"""öğrenilen zevk vektörünün tek güncelleme noktası
kural: bu fonksiyon sadece öğrenen sinyalleri işler (begendim/begenmedim/yaptim).
'gordu', 'malzeme_yok', 'cok_uzun' gibi kural-tabanli elemeler buraya HIC
ugramaz.

W4-T04: ornek ortalamasi yerine SONUMLU (ustel) ortalama kullaniliyor.
Gerekce olcumle bulundu - bkz. docs/w4-t04-ogrenen-profil-dogrulama.md:
ornek ortalamasinda n. sinyal agirligi yalnizca 1/n kadar oynatir, yani
50 kart sonrasinda kullanici zevkini degistirse motor bunu takip edemez;
sabit sinyal altinda da agirlik +-1'e yapisip kalir (olcumde satirlarin
%56'si tam +-1'di).
"""

from __future__ import annotations
from typing import Any
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.enums import TasteDimension
from app.models.recipe import UserTasteWeight

# Sonum katsayisi: kararli durumda her yeni sinyal agirligi hedefe %20
# yaklastirir. Yari omur ~3 olay; yani son ~3 kart agirligin yarisini
# belirler. Kucultmek motoru muhafazakar, buyutmek oynak yapar.
TASTE_ALPHA = 0.20

# Sinyal gucleri. 'yaptim' bir pisirme eylemidir: begenmekten agir basar.
# DIKKAT: guc dogrudan sinyal degerine DEGIL, sonum hizina uygulanir.
# Sinyali 3.0 yapmak agirligi CheckConstraint('weight BETWEEN -1 AND 1')
# disina tasirdi; hizi 3 katlamak ayni "daha cok onemse" etkisini
# araligi bozmadan verir.
STRENGTH_BEGENDIM = 1.0
STRENGTH_YAPTIM = 3.0
STRENGTH_SEVMEDIM = 1.0


def apply_taste_event(
        db: Session,
        user_id: int,
        dimension: TasteDimension,
        taste_key: str,
        signal: float,
        *,
        strength: float = 1.0,) -> None:
        satir = db.scalar(
                select(UserTasteWeight).where(
                        UserTasteWeight.user_id == user_id,
                        UserTasteWeight.dimension == dimension,
                        UserTasteWeight.taste_key == taste_key,
                )
        )
        if satir is None:
                satir = UserTasteWeight(
                        user_id = user_id, dimension = dimension, taste_key = taste_key, weight = 0.0, event_count = 0,
                )
                db.add(satir)
                db.flush()
        satir.event_count += 1

        # Soguk baslangic duzeltmesi: ilk olaylarda 1/n, sonrasinda sabit
        # TASTE_ALPHA. Bu olmasaydi ilk sinyalden sonra agirlik 1.0 degil
        # 0.20 olurdu ve tek kart begenen kullanicida zevk vektoru
        # neredeyse hic konusmazdi.
        alpha = min(1.0, max(TASTE_ALPHA, 1.0 / satir.event_count) * strength)

        # Konveks birlesim: signal ve weight [-1, 1] icindeyse sonuc da
        # oyle kalir. Aralik kisiti bu sayede kod tarafinda garanti.
        satir.weight += alpha * (signal - satir.weight)


def register_recipe_signal(
    db: Session, user_id: int, recipe_doc: dict[str, Any], *,
    signal: float, strength: float = 1.0,
) -> None:
    """Bir tarifin cuisine/difficulty/diet_tags/ingredients boyutlarina sinyali yayar."""
    zorunlu_malzemeler = [
        m["canonical_name"] for m in recipe_doc.get("ingredients", []) or []
        if m.get("canonical_name") and not m.get("optional")
    ]

    if recipe_doc.get("cuisine"):
        apply_taste_event(db, user_id, TasteDimension.CUISINE, recipe_doc["cuisine"],
                          signal, strength=strength)
    if recipe_doc.get("difficulty"):
        apply_taste_event(db, user_id, TasteDimension.DIFFICULTY, recipe_doc["difficulty"],
                          signal, strength=strength)
    for tag in recipe_doc.get("diet_tags", []) or []:
        apply_taste_event(db, user_id, TasteDimension.DIET_TAG, tag,
                          signal, strength=strength)
    for isim in zorunlu_malzemeler:
        apply_taste_event(db, user_id, TasteDimension.INGREDIENT, isim,
                          signal, strength=strength)
