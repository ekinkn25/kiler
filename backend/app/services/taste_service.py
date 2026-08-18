"""öğrenilen zevk vektörünün tek güncelleme noktası 
kural: bu fonksiyon sadece öğrenen sinyalleri işler (begendim/begenmedim/yaptim).
'gordu', 'malzeme_yok', 'cok_uzun' gibi kural-tabanli elemeler buraya HIC
ugramaz.
"""

from __future__ import annotations
from typing import Any 
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.enums import TasteDimension
from app.models.recipe import UserTasteWeight

def apply_taste_event(
        db: Session, 
        user_id: int, 
        dimension: TasteDimension, 
        taste_key: str, 
        signal: float,) -> None:
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
        satir.weight += (signal - satir.weight) / satir.event_count


def register_recipe_signal(
    db: Session, user_id: int, recipe_doc: dict[str, Any], *,
    signal: float, tekrar: int = 1,
) -> None:
    """Bir tarifin cuisine/difficulty/diet_tags/ingredients boyutlarina sinyali yayar."""
    zorunlu_malzemeler = [
        m["canonical_name"] for m in recipe_doc.get("ingredients", []) or []
        if m.get("canonical_name") and not m.get("optional")
    ]

    for _ in range(tekrar):
        if recipe_doc.get("cuisine"):
            apply_taste_event(db, user_id, TasteDimension.CUISINE, recipe_doc["cuisine"], signal)
        if recipe_doc.get("difficulty"):
            apply_taste_event(db, user_id, TasteDimension.DIFFICULTY, recipe_doc["difficulty"], signal)
        for tag in recipe_doc.get("diet_tags", []) or []:
            apply_taste_event(db, user_id, TasteDimension.DIET_TAG, tag, signal)
        for isim in zorunlu_malzemeler:
            apply_taste_event(db, user_id, TasteDimension.INGREDIENT, isim, signal)