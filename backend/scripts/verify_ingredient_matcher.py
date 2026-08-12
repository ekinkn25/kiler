"""W2-T05 dogrulama: gercek sozlukle eslestirme raporu.

    python -m scripts.verify_ingredient_matcher

Birim testleri sentetik bir sozlukle calisir (deterministik olsun diye).
Bu betik GERCEK veritabanindaki sozlukle olcer: asama dagilimi, hiz ve
gorme modelinden gelen tipik girdilerde davranis.
"""
import time

from app.db.session import SessionLocal
from app.services.ingredient_matcher import (
    clear_lookup_cache, load_lookup, match_name,
)

# Gorme modelinin ve kullanicinin gercekte urettigi tipik girdiler.
# Beklenen deger YAZMIYORUZ: gercek sozlugun icerigi zamanla degisir,
# sabit beklenti yaziriz ve betik surekli 'kirmizi' olur. Burada
# ASAMA DAGILIMINA ve gozle dogrulamaya bakiyoruz.
GIRDILER = [
    "domates", "Domates", "DOMATES", "salkım domates", "taze domates",
    "domatesler", "domats", "1 kg domates", "kiraz domates",
    "yumurta", "yumurtalar", "3 adet yumurta",
    "süt", "yarım yağlı süt", "tam yağlı süt",
    "kaşar peyniri", "kaşar", "beyaz peynir",
    "kırmızı mercimek", "k mercimek", "kırmızı mercimekler",
    "zeytinyağı", "zeytin yağı", "sızma zeytinyağı",
    "maydanoz", "taze maydanoz", "bir demet maydanoz",
    "tavuk göğsü", "tavuk", "kıyma", "dana kıyma",
    "salatalık", "salatalıklar", "soğan", "kuru soğan", "yeşil soğan",
    "ejder meyvesi", "deterjan", "bulaşık süngeri", "qwertyuiop",
]


def main() -> None:
    clear_lookup_cache()
    db = SessionLocal()
    try:
        t = time.perf_counter()
        lookup = load_lookup(db)
        yukleme_ms = (time.perf_counter() - t) * 1000
    finally:
        db.close()

    print(f"\nSozluk: {len(lookup)} malzeme, {len(lookup.fuzzy_keys)} anahtar "
          f"({yukleme_ms:.0f} ms'de yuklendi)\n")

    print(f"  {'girdi':<24} {'canonical':<24} {'asama':<14} skor")
    print(f"  {'-'*24} {'-'*24} {'-'*14} ----")

    asamalar: dict[str, int] = {}
    t = time.perf_counter()
    for girdi in GIRDILER:
        s = match_name(girdi, lookup)
        asamalar[s.matched_by] = asamalar.get(s.matched_by, 0) + 1
        print(f"  {girdi[:23]:<24} {str(s.canonical_name)[:23]:<24} "
              f"{s.matched_by:<14} {s.score}")
    toplam_ms = (time.perf_counter() - t) * 1000

    eslesen = sum(a for y, a in asamalar.items() if y != "none")
    print(f"\n{'-' * 72}")
    print(f"Eslesen: {eslesen}/{len(GIRDILER)}  (%{eslesen / len(GIRDILER):.0%})")
    print("Asama dagilimi:", ", ".join(f"{y}={a}" for y, a in sorted(asamalar.items())))
    print(f"Hiz: {len(GIRDILER)} girdi / {toplam_ms:.1f} ms "
          f"= {toplam_ms / len(GIRDILER):.2f} ms/girdi")
    print("\nDIKKAT: 'none' donen ve sozlukte OLMASI GEREKEN adlari "
          "data/ingredients_seed.json'a ekle, sonra seed'i tekrar calistir.")


if __name__ == "__main__":
    main()