"""Gorme modeli servisinin ortak tipleri, hatalari ve goruntu on islemesi."""
import base64 # data URI üretmek için
import hashlib #sha256 
import io # baytları dosya gibi okumak için 
import json
import logging
import re # markdown kod bloğunu yakalamak için 
from abc import ABC, abstractmethod #abc soyut sınıf tanımı için
from dataclasses import dataclass

from PIL import Image, ImageOps #exif_transpose için

from app.core.config import settings
from app.core.exceptions import AppError, ExternalServiceError

logger = logging.getLogger(__name__)


# ==================================================================
# Hatalar
# ==================================================================
class VisionError(ExternalServiceError):
    """Gorme modeli cagrisinda genel hata (HTTP 502)."""

    code = "vision_error"
    message = "Fotograf su anda islenemiyor."


class VisionTimeout(VisionError):
    code = "vision_timeout"
    message = "Fotograf isleme zaman asimina ugradi. Tekrar dener misin?"


class VisionRateLimited(VisionError):
    code = "vision_rate_limited"
    message = "Su anda cok yogunuz. Birazdan tekrar dene."


class VisionInvalidResponse(VisionError):
    code = "vision_invalid_response"
    message = "Fotograftan anlamli bir sonuc cikaramadim."


class ImageTooLarge(AppError):
    status_code = 413
    code = "image_too_large"
    message = "Fotograf cok buyuk."


# ==================================================================
# Sonuc tipleri
# ==================================================================
@dataclass(frozen=True, slots=True) #  frozen=True → nesne oluşturulduktan sonra alanları değiştirilemez ||||| slots = True -> __dict__ yerine __slots__ kullanır her nesne için sözlük yaratılmaz bellek düşer öznitelik erişimi hızlanır
class VisionUsage:
    """Tek cagrinin maliyet ve performans olculeri."""

    provider: str
    model: str | None
    prompt_tokens: int | None
    completion_tokens: int | None
    latency_ms: int
    image_bytes: int


@dataclass(frozen=True, slots=True)
class VisionResult:
    """Gorme modelinin donusu.

    data     : ayristirilmis JSON (asil sonuc)
    raw_text : modelin ham metni - hata ayiklama ve W4-T11 olcumu icin
    usage    : maliyet/performans
    """

    data: dict
    raw_text: str
    usage: VisionUsage


# ==================================================================
# Goruntu on isleme
# ==================================================================
def prepare_image(raw: bytes) -> tuple[bytes, str]:
    """Fotografi kucultup sikistirir ve SHA-256 ozetini uretir.

    NEDEN: Gorme modellerinde maliyet goruntu boyutuyla dogru orantilidir.
    3 MB'lik bir telefon fotografini 1600 px / %80 kaliteye indirmek
    dogrulugu neredeyse hic dusurmeden maliyeti 5-8 kat azaltir.

    EXIF de temizlenir: (a) konum bilgisi tasiyabilir - KVKK,
    (b) donme bilgisi uygulanip atilir, yoksa yan yatmis fotograf gider.
    """
    if len(raw) > 15 * 1024 * 1024:
        raise ImageTooLarge("Fotograf 15 MB'tan buyuk olamaz.")

    try:
        img = Image.open(io.BytesIO(raw))
        img = ImageOps.exif_transpose(img)      # donmeyi uygula, EXIF'i birak
        img = img.convert("RGB")                # PNG saydamligi JPEG'e cevrilir
    except Exception as exc:  # noqa: BLE001
        raise VisionInvalidResponse(f"Goruntu okunamadi: {exc}") from exc

    en_buyuk = settings.VISION_MAX_IMAGE_PX
    if max(img.size) > en_buyuk: #(genişil, yükseklik) max ile uzun kenara bakılır thumbnail ise en boy oranını koruyarak nesneyi yerinde değiştirir
        img.thumbnail((en_buyuk, en_buyuk), Image.LANCZOS) # en kaliteli yeniden örnekleme filtresidir küçültmede metin ve ince detayları en iyi koruyan seçenektir. OCR için doğru tercihtir.

    tampon = io.BytesIO()
    img.save(tampon, format="JPEG", quality=settings.VISION_JPEG_QUALITY, optimize=True) #burada exif atıldı|jpeg aydamlık desteklemez  |optimize ile Huffman tablolarını ikinci bir geçişle optimize eder ve yüzde üç-beş daha küçük dosya kaplar fakat biraz daha fazla cpu kullanımı olur
    islenmis = tampon.getvalue()

    ozet = hashlib.sha256(islenmis).hexdigest()
    logger.debug("Goruntu isleme: %d KB -> %d KB", len(raw) // 1024, len(islenmis) // 1024)
    return islenmis, ozet 
    #fnk bytes,str döndürür: gönderilecek görüntü, ön bellek anahtarı


def to_data_uri(image_bytes: bytes) -> str:
    """Goruntuyu API'lerin bekledigi data URI bicimine cevirir."""
    return f"data:image/jpeg;base64,{base64.b64encode(image_bytes).decode()}"


# ==================================================================
# JSON ayristirma
# ==================================================================
_FENCE = re.compile(r"```(?:json)?\s*(.*?)\s*```", re.DOTALL)


def extract_json(text: str) -> dict:
    """Model yanitindan JSON cikarir.

    Modeller JSON istense bile bazen markdown kod blogu icine sarar veya
    basina 'Iste sonuc:' gibi bir cumle ekler. Uc asamali deneme yapiyoruz.
    """
    if not text or not text.strip():
        raise VisionInvalidResponse("Model bos yanit dondu.")

    # 1) Dogrudan JSON
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # 2) Markdown kod blogu icinde
    if m := _FENCE.search(text):
        try:
            return json.loads(m.group(1))
        except json.JSONDecodeError:
            pass

    # 3) Metnin icindeki ilk { ... } veya [ ... ] blogu
    for acilis, kapanis in (("{", "}"), ("[", "]")):
        bas, son = text.find(acilis), text.rfind(kapanis)
        if bas != -1 and son > bas:
            try:
                cozulen = json.loads(text[bas:son + 1])
                return cozulen if isinstance(cozulen, dict) else {"items": cozulen}
            except json.JSONDecodeError:
                continue

    logger.warning("JSON ayristirilamadi. Ham yanit: %s", text[:400])
    raise VisionInvalidResponse("Model gecerli JSON dondurmedi.")


# ==================================================================
# Soyut arayuz
# ==================================================================
class VisionProvider(ABC):
    """Gorme modeli saglayicisinin sozlesmesi.

    Cagiran kod (W2-T04, W2-T08) hangi saglayicinin arkada oldugunu BILMEZ.
    Yeni bir saglayici eklemek = bu sinifi miras alan yeni bir sinif yazmak.
    """

    name: str = "abstract"

    @abstractmethod
    async def analyze(self, image_bytes: bytes, prompt: str) -> VisionResult:
        """Fotografi ve talimati modele gonderir, ayristirilmis JSON doner.

        Hata durumunda VisionError alt siniflarindan biri firlatir;
        cagiran kod HTTP ayrintilariyla ugrasmaz.
        """

    @property
    def is_fake(self) -> bool:
        return False