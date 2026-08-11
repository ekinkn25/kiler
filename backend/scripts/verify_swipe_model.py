"""W2-T02 dogrulama: swipe oturumu ve geri bildirim modeli.

Kullanim (backend/ klasorunde):  python -m scripts.verify_swipe_model
Bellek-ici veritabani kullanir; kalori.db'ye DOKUNMAZ.
"""
from datetime import timedelta

from sqlalchemy import create_engine, event, inspect, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.db.base import Base
import app.models  # noqa: F401
from app.models import Category, Ingredient, RecipeFeedback, SwipeSession, User
from app.models.enums import FeedbackAction, FeedbackReason
from app.models.recipe import (
    ids_already_planned, ids_missing_ingredient_recent,
    ids_permanently_disliked, ids_seen_in_session, utcnow,
)

basarili = basarisiz = 0
R1, R2, R3, R4 = ("aaa" * 8), ("bbb" * 8), ("ccc" * 8), ("ddd" * 8)


def kontrol(ad, kosul, ek=""):
    global basarili, basarisiz
    if kosul:
        print(f"  [TAMAM] {ad} {ek}")
        basarili += 1
    else:
        print(f"  [HATA ] {ad} {ek}")
        basarisiz += 1


engine = create_engine("sqlite:///:memory:", future=True)


@event.listens_for(Engine, "connect")
def _pragma(conn, rec):
    cur = conn.cursor(); cur.execute("PRAGMA foreign_keys=ON"); cur.close()


def main() -> None:
    Base.metadata.create_all(engine)
    ins = inspect(engine)

    print("\n1) Sema")
    kontrol("swipe_sessions tablosu var", "swipe_sessions" in ins.get_table_names())
    fb = {c["name"] for c in ins.get_columns("recipe_feedback")}
    for ad in ("reason", "missing_ingredient_id", "session_id"):
        kontrol(f"recipe_feedback.{ad} var", ad in fb)
    idx = {i["name"] for i in ins.get_indexes("recipe_feedback")}
    for ad in ("ix_feedback_user_recipe", "ix_feedback_session",
               "ix_feedback_user_reason_time"):
        kontrol(f"Indeks '{ad}'", ad in idx)

    with Session(engine) as db:
        u = User(email="t@ornek.com", hashed_password="x")
        kat = Category(code="bakliyat", display_name="Bakliyat")
        mal = Ingredient(canonical_name="tahin", display_name="Tahin", category=kat)
        db.add_all([u, kat, mal]); db.flush()

        o1 = SwipeSession(user_id=u.id)
        o2 = SwipeSession(user_id=u.id)
        db.add_all([o1, o2]); db.flush()

        db.add_all([
            # oturum 1: gordu / sevmedim / malzeme yok / yapacagim
            RecipeFeedback(user_id=u.id, recipe_id=R1, session_id=o1.id,
                           action=FeedbackAction.GORDU),
            RecipeFeedback(user_id=u.id, recipe_id=R2, session_id=o1.id,
                           action=FeedbackAction.BEGENMEDIM,
                           reason=FeedbackReason.SEVMEDIM),
            RecipeFeedback(user_id=u.id, recipe_id=R3, session_id=o1.id,
                           action=FeedbackAction.BEGENMEDIM,
                           reason=FeedbackReason.MALZEME_YOK,
                           missing_ingredient_id=mal.id),
            RecipeFeedback(user_id=u.id, recipe_id=R4, session_id=o1.id,
                           action=FeedbackAction.YAPACAGIM),
        ])
        db.commit()

        print("\n2) Ayni tarif farkli oturumlarda")
        db.add(RecipeFeedback(user_id=u.id, recipe_id=R1, session_id=o2.id,
                              action=FeedbackAction.YAPACAGIM))
        db.commit()
        n = db.scalar(select(func_count := __import__("sqlalchemy").func.count())
                      .select_from(RecipeFeedback).where(RecipeFeedback.recipe_id == R1))
        kontrol("Ayni tarife iki oturumda iki kayit yazilabiliyor", n == 2, f"-> {n}")

        print("\n3) Filtre yardimcilari")
        gorulen1 = set(db.scalars(ids_seen_in_session(o1.id)))
        kontrol("ids_seen_in_session 4 tarif donuyor", len(gorulen1) == 4, f"-> {len(gorulen1)}")
        gorulen2 = set(db.scalars(ids_seen_in_session(o2.id)))
        kontrol("Oturum 2 yalniz kendi tarifini goruyor", gorulen2 == {R1})

        kalici = set(db.scalars(ids_permanently_disliked(u.id)))
        kontrol("'sevmedim' kalici elemede", kalici == {R2})

        eksik = set(db.scalars(ids_missing_ingredient_recent(u.id)))
        kontrol("'malzeme_yok' 7 gunluk elemede", eksik == {R3})

        planli = set(db.scalars(ids_already_planned(u.id)))
        kontrol("'yapacagim' kisa sureli elemede", R4 in planli)

        print("\n4) Kisitlar")
        for ad, kayit in [
            ("reason yalniz 'begenmedim' ile",
             RecipeFeedback(user_id=u.id, recipe_id=R1, action=FeedbackAction.YAPACAGIM,
                            reason=FeedbackReason.SEVMEDIM)),
            ("missing_ingredient yalniz 'malzeme_yok' ile",
             RecipeFeedback(user_id=u.id, recipe_id=R1, action=FeedbackAction.BEGENMEDIM,
                            reason=FeedbackReason.SEVMEDIM, missing_ingredient_id=mal.id)),
            ("rating 1-5 disinda reddediliyor",
             RecipeFeedback(user_id=u.id, recipe_id=R1, action=FeedbackAction.YAPTIM,
                            rating=9)),
        ]:
            try:
                db.add(kayit); db.commit()
                kontrol(ad, False, "-> kabul edildi!")
            except Exception:
                db.rollback()
                kontrol(ad, True)

        print("\n5) Oturum filtreleri")
        o1.tighten_time_limit(30)
        db.commit()
        kontrol("'cok uzun' sure esigi 30 dk yapiyor", o1.filters.get("max_total_time") == 30)
        o1.tighten_time_limit(45)
        db.commit()
        kontrol("Esik geri GENISLEMIYOR", o1.filters.get("max_total_time") == 30,
                f"-> {o1.filters.get('max_total_time')}")

        print("\n6) CASCADE")
        uid = u.id
        db.delete(db.get(User, uid)); db.commit()
        kalan = db.query(SwipeSession).count() + db.query(RecipeFeedback).count()
        kontrol("Kullanici silininde oturum ve geri bildirimler siliniyor", kalan == 0,
                f"-> {kalan} kayit kaldi")
        kontrol("Malzeme sozlugu korundu", db.query(Ingredient).count() == 1)

    print(f"\n{'-' * 52}")
    print(f"SONUC: {basarili} basarili, {basarisiz} basarisiz")


if __name__ == "__main__":
    main()