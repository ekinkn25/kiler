"""W2-T06 dogrulama: kiler agirlikli skorlama.

    python -m scripts.verify_recipe_scoring

MongoDB baglantisi ve seed edilmis tarifler GEREKTIRIR.
Tarif yoksa once: python -m scripts.seed_recipes
"""
import asyncio
import sys

from sqlalchemy import select

from app.core.config import settings
from app.db.mongo_schema import RECIPE_COLLECTION
from app.db.mongodb import close_mongo_connection, connect_to_mongo, mongo
from app.db.session import SessionLocal
from app.models import Allergen, Ingredient, PantryItem, User
from app.models.enums import Availability, PantrySource
from app.services.recipe_scoring import build_context, score_recipes

basarili = basarisiz = 0
TEST_MALZEME = "domates"


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


def test_kullanicisi(db) -> User:
    kullanici = db.query(User).first()
    if kullanici is None:
        from app.core.security import hash_password
        kullanici = User(email="skor_test@example.com",
                         hashed_password=hash_password("Test1234!"))
        db.add(kullanici)
        db.commit()
        db.refresh(kullanici)
    return kullanici


def kileri_ayarla(db, kullanici, canonical: str, durum: Availability | None):
    """Kileri sifirlar ve tek bir malzemeyi verilen duruma getirir."""
    db.query(PantryItem).filter(PantryItem.user_id == kullanici.id).delete()
    db.commit()
    if durum is None:
        return None

    malzeme = db.scalar(
        select(Ingredient).where(Ingredient.canonical_name == canonical)
    )
    if malzeme is None:
        sys.exit(f"'{canonical}' sozlukte yok. Once: python -m scripts.seed_reference_data")

    kayit = PantryItem(
        user_id=kullanici.id, ingredient_id=malzeme.id,
        availability=durum, source=PantrySource.FOTO,
    )
    if durum == Availability.VAR:
        kayit.confirm(PantrySource.FOTO, confidence=1.0)
    db.add(kayit)
    db.commit()
    return malzeme


def yazdir(baslik, sonuclar, n=8):
    print(f"\n  {baslik}")
    print(f"  {'#':<3}{'tarif':<34}{'skor':<8}{'kiler':<8}{'eslesen'}")
    print(f"  {'-'*3}{'-'*34}{'-'*8}{'-'*8}{'-'*20}")
    for i, t in enumerate(sonuclar[:n], 1):
        k = t["score_breakdown"]
        print(f"  {i:<3}{t['title'][:33]:<34}{t['final_score']:<8}"
              f"{k['pantry']:<8}{','.join(t['matched_ingredients']) or '-'}")


async def main() -> None:
    await connect_to_mongo()
    if not mongo.is_connected:
        sys.exit("MongoDB baglantisi yok. .env icindeki MONGODB_URI'yi kontrol et.")

    adet = await mongo.database[RECIPE_COLLECTION].count_documents({})
    print(f"\nKoleksiyonda {adet} tarif var.")
    if adet == 0:
        sys.exit("Once tarifleri seed et: python -m scripts.seed_recipes")

    db = SessionLocal()
    kullanici = test_kullanicisi(db)
    eski_alerjenler = list(kullanici.allergens)
    kullanici.allergens.clear()
    db.commit()

    try:
        # ---------------------------------------------------------- 1
        print("\n1) Bos kiler (temel cizgi)")
        kileri_ayarla(db, kullanici, TEST_MALZEME, None)
        db.refresh(kullanici)
        bos = await score_recipes(mongo.database, build_context(db, kullanici), limit=50)
        kontrol("Sonuc donuyor", len(bos) > 0, f"-> {len(bos)} tarif")
        kontrol("Bos kilerde kiler skoru 0",
                all(t["score_breakdown"]["pantry"] == 0 for t in bos))
        yazdir("Bos kiler - ilk 5:", bos, 5)
        bos_sira = {t["id"]: i for i, t in enumerate(bos)}

        # ---------------------------------------------------------- 2
        print(f"\n2) Kilerde '{TEST_MALZEME}' VAR  <-- kabul kriteri")
        kileri_ayarla(db, kullanici, TEST_MALZEME, Availability.VAR)
        db.refresh(kullanici)
        ctx = build_context(db, kullanici)
        kontrol("Baglamda malzeme var", TEST_MALZEME in ctx.var)

        varken = await score_recipes(mongo.database, ctx, limit=50)
        yazdir(f"'{TEST_MALZEME}' varken - ilk 8:", varken)

        domatesli = [t for t in varken if TEST_MALZEME in t["matched_ingredients"]]
        kontrol(f"'{TEST_MALZEME}' iceren tarif bulundu",
                len(domatesli) > 0, f"-> {len(domatesli)} tarif")

        if domatesli:
            ilk10 = {t["id"] for t in varken[:10]}
            kontrol("Domatesli tarifler ILK 10'a girdi  <-- kabul kriteri",
                    any(t["id"] in ilk10 for t in domatesli))

            yukselen = sum(
                1 for t in domatesli
                if t["id"] in bos_sira
                and varken.index(t) < bos_sira[t["id"]]
            )
            kontrol("Domatesli tarifler siralamada YUKSELDI",
                    yukselen > 0, f"-> {yukselen}/{len(domatesli)} tarif yukseldi")

            ornek = domatesli[0]
            kontrol("Kiler skoru sifirdan buyuk",
                    ornek["score_breakdown"]["pantry"] > 0,
                    f"-> {ornek['score_breakdown']['pantry']}")

        # ---------------------------------------------------------- 3
        print(f"\n3) Ayni malzeme 'BILINMIYOR' -> 0.4 agirlik")
        kileri_ayarla(db, kullanici, TEST_MALZEME, Availability.BILINMIYOR)
        db.refresh(kullanici)
        belirsiz = await score_recipes(db_ctx := mongo.database,
                                       build_context(db, kullanici), limit=50)
        if domatesli:
            hedef = domatesli[0]["id"]
            v = next((t for t in varken if t["id"] == hedef), None)
            b = next((t for t in belirsiz if t["id"] == hedef), None)
            if v and b:
                oran = b["score_breakdown"]["pantry"] / v["score_breakdown"]["pantry"]
                kontrol("'bilinmiyor' kiler skorunu ~0.4 katina dusuruyor",
                        abs(oran - settings.PANTRY_UNKNOWN_WEIGHT) < 0.02,
                        f"-> oran {oran:.2f}")
                kontrol("'bilinmiyor' final skoru da dusuruyor",
                        b["final_score"] < v["final_score"])

        # ---------------------------------------------------------- 4
        print("\n4) Alerjen filtresi  <-- kabul kriteri")
        kileri_ayarla(db, kullanici, TEST_MALZEME, Availability.VAR)
        alerjen = db.scalar(select(Allergen).where(Allergen.code == "gluten"))
        if alerjen is None:
            print("  (atlandi: 'gluten' alerjeni sozlukte yok)")
        else:
            glutenli = await mongo.database[RECIPE_COLLECTION].count_documents(
                {"allergens": "gluten"}
            )
            print(f"  (koleksiyonda {glutenli} glutenli tarif var)")

            kullanici.allergens.append(alerjen)
            db.commit()
            db.refresh(kullanici)

            suzulmus = await score_recipes(
                mongo.database, build_context(db, kullanici), limit=200
            )
            kontrol("ALERJENLI TARIF HIC DONMUYOR  <-- kabul kriteri",
                    all("gluten" not in t["allergens"] for t in suzulmus),
                    f"-> {len(suzulmus)} tarif tarandi")
            kontrol("Filtre sonrasi hala oneri var", len(suzulmus) > 0)

            kullanici.allergens.clear()
            db.commit()

        # ---------------------------------------------------------- 5
        print("\n5) Skor kirilimi (aciklanabilirlik)")
        ornek = varken[0]
        k = ornek["score_breakdown"]
        kontrol("Dort bilesen de var",
                {"pantry", "calorie", "taste", "time"} <= set(k))
        kontrol("Agirliklar yanitta", "weights" in k)
        kontrol("Bilesenler 0-1 araliginda",
                all(0 <= k[a] <= 1 for a in ("pantry", "calorie", "taste", "time")))
        hesap = sum(k[a] * k["weights"][a]
                    for a in ("pantry", "calorie", "taste", "time"))
        kontrol("Kirilim final skoru DOGRULUYOR",
                abs(hesap - ornek["final_score"]) < 0.001,
                f"-> {hesap:.4f} vs {ornek['final_score']}")
        kontrol("Eksik malzeme listesi var", "missing_ingredients" in ornek)
        print(f"\n  Ornek: {ornek['title']}")
        print(f"    kiler={k['pantry']} kalori={k['calorie']} "
              f"zevk={k['taste']} sure={k['time']} -> {ornek['final_score']}")
        print(f"    eslesen={ornek['matched_ingredients']}")
        print(f"    eksik  ={ornek['missing_ingredients'][:5]}")

    finally:
        kileri_ayarla(db, kullanici, TEST_MALZEME, None)
        kullanici.allergens.clear()
        for a in eski_alerjenler:
            kullanici.allergens.append(a)
        db.commit()
        db.close()
        await close_mongo_connection()

    print(f"\n{'-' * 60}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")
    sys.exit(1 if basarisiz else 0)


if __name__ == "__main__":
    asyncio.run(main())