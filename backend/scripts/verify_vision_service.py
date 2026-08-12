"""W2-T03 dogrulama: gorme servisi soyutlamasi.

Kullanim (backend/ klasorunde):  python -m scripts.verify_vision_service
Ag baglantisi GEREKTIRMEZ - sahte saglayici ile calisir.
"""
import asyncio
import io
import json

from PIL import Image

from app.core.config import settings
from app.services.vision import (
    FakeVisionProvider, GroqVisionProvider, OpenAIVisionProvider,
    extract_json, get_vision_provider, prepare_image, reset_vision_provider,
    to_data_uri,
)
from app.services.vision.base import VisionInvalidResponse

basarili = basarisiz = 0


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def sahte_fotograf(genislik=4000, yukseklik=3000) -> bytes:
    """Buyuk, gurultulu bir test goruntusu uretir (sikismayi zorlastirmak icin)."""
    import random
    img = Image.new("RGB", (genislik, yukseklik))
    px = img.load()
    for x in range(0, genislik, 8):
        for y in range(0, yukseklik, 8):
            renk = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
            for dx in range(8):
                for dy in range(8):
                    if x + dx < genislik and y + dy < yukseklik:
                        px[x + dx, y + dy] = renk
    tampon = io.BytesIO()
    img.save(tampon, format="JPEG", quality=95)
    return tampon.getvalue()


async def main() -> None:
    print("\n1) Goruntu on isleme")
    ham = sahte_fotograf()
    islenmis, ozet = prepare_image(ham)
    kontrol("Boyut kucultuldu", len(islenmis) < len(ham),
            f"-> {len(ham)//1024} KB => {len(islenmis)//1024} KB")
    kontrol("Cozunurluk sinirlandi",
            max(Image.open(io.BytesIO(islenmis)).size) <= settings.VISION_MAX_IMAGE_PX,
            f"-> {Image.open(io.BytesIO(islenmis)).size}")
    kontrol("SHA-256 ozeti uretildi", len(ozet) == 64)
    _, ozet2 = prepare_image(ham)
    kontrol("Ayni fotograf ayni ozeti veriyor (onbellek icin)", ozet == ozet2)
    kontrol("Data URI dogru bicimde",
            to_data_uri(islenmis).startswith("data:image/jpeg;base64,"))

    print("\n2) JSON ayristirma dayanikliligi")
    for ad, metin, beklenen in [
        ("Duz JSON", '{"a": 1}', {"a": 1}),
        ("Markdown blogu icinde", '```json\n{"a": 1}\n```', {"a": 1}),
        ("Aciklama cumlesiyle", 'Iste sonuc:\n{"a": 1}\nUmarim yardimci olur.', {"a": 1}),
        ("Dizi -> items", '[{"n": "domates"}]', {"items": [{"n": "domates"}]}),
    ]:
        try:
            kontrol(ad, extract_json(metin) == beklenen)
        except Exception as exc:  # noqa: BLE001
            kontrol(ad, False, f"-> {exc}")

    try:
        extract_json("bu metinde hic json yok")
        kontrol("Gecersiz yanit reddediliyor", False, "-> kabul edildi!")
    except VisionInvalidResponse:
        kontrol("Gecersiz yanit reddediliyor", True)

    print("\n3) Saglayici secimi")
    reset_vision_provider()
    orijinal = settings.VISION_PROVIDER

    settings.VISION_PROVIDER = "fake"
    reset_vision_provider()
    kontrol("VISION_PROVIDER=fake -> FakeVisionProvider",
            isinstance(get_vision_provider(), FakeVisionProvider))

    settings.VISION_PROVIDER = "groq"
    reset_vision_provider()
    kontrol("VISION_PROVIDER=groq -> GroqVisionProvider",
            isinstance(get_vision_provider(), GroqVisionProvider))

    settings.VISION_PROVIDER = "openai"
    reset_vision_provider()
    kontrol("VISION_PROVIDER=openai -> OpenAIVisionProvider",
            isinstance(get_vision_provider(), OpenAIVisionProvider))

    settings.VISION_PROVIDER = "saçmasapan"
    reset_vision_provider()
    kontrol("Bilinmeyen saglayici -> sahteye dusuyor (uygulama cokmuyor)",
            isinstance(get_vision_provider(), FakeVisionProvider))

    settings.VISION_PROVIDER = orijinal or "fake"
    reset_vision_provider()

    print("\n4) Sahte saglayici")
    settings.VISION_PROVIDER = "fake"
    reset_vision_provider()
    saglayici = get_vision_provider()
    kontrol("is_fake bayragi dogru", saglayici.is_fake)

    malzeme = await saglayici.analyze(islenmis, "Bu fotograftaki malzemeleri listele")
    kontrol("Malzeme istegi 'items' donduruyor", "items" in malzeme.data,
            f"-> {len(malzeme.data.get('items', []))} malzeme")
    kontrol("Her malzemede confidence var",
            all("confidence" in m for m in malzeme.data["items"]))
    kontrol("Dusuk guvenli ornek var (onay ekrani testi icin)",
            any(m["confidence"] < 0.5 for m in malzeme.data["items"]))

    ogun = await saglayici.analyze(islenmis, "Bu tabaktaki yemegi ve porsiyonu tahmin et")
    kontrol("Ogun istegi 'dish_name' donduruyor", "dish_name" in ogun.data,
            f"-> {ogun.data.get('dish_name')}")
    kontrol("Porsiyon tahmini var", "portion" in ogun.data and "estimated_grams" in ogun.data)

    print("\n5) Kullanim olculeri")
    k = malzeme.usage
    kontrol("Saglayici adi kayitli", k.provider == "fake")
    kontrol("Gecikme olculuyor", k.latency_ms >= 0, f"-> {k.latency_ms} ms")
    kontrol("Goruntu boyutu kayitli", k.image_bytes == len(islenmis))
    kontrol("Ham metin saklaniyor (hata ayiklama icin)", len(malzeme.raw_text) > 0)

    print("\n6) Performans")
    import time
    t = time.perf_counter()
    await saglayici.analyze(islenmis, "malzemeleri listele")
    sure = time.perf_counter() - t
    kontrol("Sahte saglayici 5 sn altinda", sure < 5, f"-> {sure:.2f} sn")

    print(f"\n{'-' * 52}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    print(f"Aktif saglayici: {get_vision_provider().name}")


if __name__ == "__main__":
    asyncio.run(main())