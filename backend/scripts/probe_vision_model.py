"""Gorme modeli teshis betigi. Groq/OpenAI icin.

    python -m scripts.probe_vision_model                 -> saglayicidaki modelleri listeler
    python -m scripts.probe_vision_model <model_kimligi> -> o modeli 3 varyantla dener

Amaci: '400 json_validate_failed' hatasinin sebebini DARALTMAK.
  A) Sadece metin + JSON modu  -> anahtar ve model kimligi dogru mu?
  B) Resim + JSON modu KAPALI  -> model resmi gerçekten goruyor mu?
  C) Resim + JSON modu ACIK    -> ikisi birlikte destekleniyor mu?
"""
import asyncio
import json
import sys
from pathlib import Path

import httpx

from app.core.config import settings
from app.services.vision import prepare_image, to_data_uri

TABAN_ADRESLER = {
    "groq": "https://api.groq.com/openai/v1",
    "openai": "https://api.openai.com/v1",
}


def taban_adres() -> str:
    ad = (settings.VISION_PROVIDER or "").lower().strip()
    if ad not in TABAN_ADRESLER:
        sys.exit(f".env icinde VISION_PROVIDER 'groq' veya 'openai' olmali (su an: '{ad}')")
    return TABAN_ADRESLER[ad]


def basliklar() -> dict:
    if not settings.VISION_API_KEY:
        sys.exit(".env icinde VISION_API_KEY bos.")
    return {"Authorization": f"Bearer {settings.VISION_API_KEY}"}


async def modelleri_listele() -> None:
    async with httpx.AsyncClient(timeout=30) as istemci:
        yanit = await istemci.get(f"{taban_adres()}/models", headers=basliklar())
    if yanit.status_code != 200:
        print(f"HATA {yanit.status_code}: {yanit.text[:400]}")
        return

    modeller = sorted(m["id"] for m in yanit.json().get("data", []))
    print(f"\n{settings.VISION_PROVIDER} uzerinde {len(modeller)} model:\n")
    for m in modeller:
        # Isaret koymuyoruz: model adindan gorme yetenegini TAHMIN ETMEK
        # yanlis yonlendirir. Adaylari asagidaki komutla tek tek dene.
        print(f"  {m}")
    print("\nSecdigin modeli dene:  python -m scripts.probe_vision_model <model_kimligi>")


def test_goruntusu() -> bytes:
    yol = Path(__file__).resolve().parents[2] / "data" / "test_fotograf.jpg"
    if not yol.exists():
        sys.exit(f"Test fotografi bulunamadi: {yol}")
    islenmis, _ = prepare_image(yol.read_bytes())
    return islenmis


async def dene(istemci, model: str, ad: str, govde: dict) -> bool:
    print(f"\n--- {ad}")
    yanit = await istemci.post(
        f"{taban_adres()}/chat/completions", headers=basliklar(), json=govde
    )
    if yanit.status_code != 200:
        print(f"  BASARISIZ {yanit.status_code}: {yanit.text[:400]}")
        return False, yanit.status_code, yanit.tect
    try:
        metin = yanit.json()["choices"][0]["message"]["content"]
    except (KeyError, IndexError):
        print(f"  Beklenmeyen yanit bicimi: {json.dumps(yanit.json())[:300]}")
        return False
    print(f"  TAMAM. Model cikti: {metin[:300]}")
    return True, 200, metin


async def modeli_dene(model: str) -> None:
    goruntu = test_goruntusu()
    resim_blogu = {"type": "image_url", "image_url": {"url": to_data_uri(goruntu)}}
    soru = "Bu fotograftaki yenilebilir malzemeleri JSON olarak listele: {\"items\": [{\"name\": \"...\", \"confidence\": 0.9}]}"

    print(f"\nModel: {model} | saglayici: {settings.VISION_PROVIDER}")
    async with httpx.AsyncClient(timeout=60) as istemci:
        a = await dene(istemci, model, "A) Sadece metin + JSON modu", {
            "model": model,
            "messages": [{"role": "user",
                          "content": "Bana su JSON nesnesini dondur: {\"ok\": true}"}],
            "response_format": {"type": "json_object"},
            "max_tokens": 100,
        })

        b = await dene(istemci, model, "B) Resim + JSON modu KAPALI", {
            "model": model,
            "messages": [{"role": "user",
                          "content": [{"type": "text", "text": soru}, resim_blogu]}],
            "temperature": 0.1,
            "max_tokens": 2048,
        })

        c = await dene(istemci, model, "C) Resim + JSON modu ACIK", {
            "model": model,
            "messages": [{"role": "user",
                          "content": [{"type": "text", "text": soru}, resim_blogu]}],
            "response_format": {"type": "json_object"},
            "temperature": 0.1,
            "max_tokens": 2048,
        })

    print("\n" + "=" * 60)
    print("TEHSIS:")
    a_ok, a_kod, a_metin = a
    b_ok, b_kod, b_metin = b
    c_ok, c_kod, c_metin = c

    if a_kod in (401, 403):
        print("  Anahtar gecersiz veya yetkisiz.")
    elif a_kod == 404:
        print("  Model kimligi bulunamadi.")
    elif not b_ok and b_kod != 429:
        print("  Model RESIM KABUL ETMIYOR. Baska model sec.")
    elif "<think>" in b_metin or "json_validate_failed" in a_metin:
        print("  Bu bir AKIL YURUTME modeli; JSON modunu <think> blogu bozuyor.")
        print("     Cozum: VISION_JSON_MODE=false + extract_json'da <think> temizligi.")
    elif 429 in (a_kod, b_kod, c_kod):
        print("  Kota (TPM) doldu. VISION_MAX_IMAGE_PX'i dusur, bir dakika bekle.")
    elif c_ok:
        print("  Hepsi gecti -> bu modeli VISION_MODEL olarak kullanabilirsin.")
    print("=" * 60)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        asyncio.run(modeli_dene(sys.argv[1]))
    else:
        asyncio.run(modelleri_listele())