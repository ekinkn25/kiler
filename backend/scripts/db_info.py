"""Veritabaninin guncel durumunu ozetler.

Kullanim (backend/ klasorunde):  python -m scripts.db_info
"""
import sqlite3

from app.core.config import settings

DB_PATH = settings.DATABASE_URL.replace("sqlite:///", "")


def main() -> None:
    con = sqlite3.connect(DB_PATH)

    tablolar = sorted(n for n, t in con.execute("select name, type from sqlite_master") if t == "table")
    indeksler = sorted(n for n, t in con.execute("select name, type from sqlite_master") if t == "index" and n)

    print(f"Veritabani : {DB_PATH}")
    print(f"Tablo      : {len(tablolar)}  (22 tablo + alembic_version = 23 olmali)")
    for t in tablolar:
        print(f"   - {t}")

    print(f"\nIndeks     : {len(indeksler)}")

    surum = con.execute("select version_num from alembic_version").fetchone()
    print(f"\nAlembic surumu : {surum[0] if surum else 'YOK'}")

    fk = con.execute("pragma foreign_keys").fetchone()[0]
    print(f"PRAGMA foreign_keys : {fk}  (bu betikte 0 normaldir; uygulama acarken 1 olur)")

    print("\nCHECK kisiti iceren tablolar:")
    for ad, sql in con.execute("select name, sql from sqlite_master"):
        if sql and "CHECK" in sql:
            sayi = sql.count("CHECK")
            print(f"   - {ad}: {sayi} adet")

    con.close()


if __name__ == "__main__":
    main()