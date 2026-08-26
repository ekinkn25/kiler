"""W4-T13: N+1 regresyon testi.

Sure olcmuyoruz - makineye gore degisir, kirilgan test olur. SORGU SAYISI
olcuyoruz: kilerde 3 kalem varken de 30 kalem varken de ayni olmali.
"""
import pytest
from sqlalchemy import event, select
from sqlalchemy.engine import Engine

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import Ingredient, PantryItem, User
from app.models.enums import PantrySource
from app.services import pantry_service


class SorguSayaci:
    def __init__(self):
        self.n = 0

    def __enter__(self):
        event.listen(Engine, "after_cursor_execute", self._say)
        return self

    def __exit__(self, *_):
        event.remove(Engine, "after_cursor_execute", self._say)

    def _say(self, conn, cursor, statement, parameters, context, executemany):
        self.n += 1


@pytest.fixture
def db():
    oturum = SessionLocal()
    yield oturum
    oturum.rollback()
    oturum.close()


@pytest.fixture
def kullanici(db):
    """Testin kendi kullanicisi. Sonunda kiler kayitlari geri alinir."""
    k = db.scalar(select(User).where(User.email == "nplus1_test@example.com"))
    if k is None:
        k = User(email="nplus1_test@example.com", hashed_password=hash_password("T1234!"))
        db.add(k)
        db.commit()
        db.refresh(k)
    db.query(PantryItem).filter(PantryItem.user_id == k.id).delete()
    db.commit()
    return k


def kilere_ekle(db, user, malzemeler):
    """Verilen malzemeleri kilere 'var' olarak yazar."""
    for m in malzemeler:
        kayit = PantryItem(user_id=user.id, ingredient_id=m.id)
        kayit.confirm(PantrySource.MANUEL)
        db.add(kayit)
    db.commit()


def test_kiler_listesi_sabit_sorgu(db, kullanici):
    """3 kalem ve 15 kalem AYNI sayida sorgu atmali."""
    malzemeler = list(db.scalars(select(Ingredient).order_by(Ingredient.id).limit(15)))
    if len(malzemeler) < 15:
        pytest.skip("Sozluk seed edilmemis: python -m scripts.seed_reference_data")

    kilere_ekle(db, kullanici, malzemeler[:3])
    with SorguSayaci() as s1:
        for k in pantry_service.list_items(db, kullanici):
            _ = k.ingredient.display_name      # serilestirmenin yaptigi sey
            _ = k.product

    kilere_ekle(db, kullanici, malzemeler[3:15])
    with SorguSayaci() as s2:
        for k in pantry_service.list_items(db, kullanici):
            _ = k.ingredient.display_name
            _ = k.product

    assert s1.n == s2.n, (
        f"N+1: 3 kalemde {s1.n}, 15 kalemde {s2.n} sorgu. "
        "list_items'ta joinedload eksik."
    )