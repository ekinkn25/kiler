from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

# Alembic'in SQLite'ta "batch mode" ile calisabilmesi icin TUM kisitlarin
# ongorulebilir bir adi olmalidir. Adsiz kisitlar yeniden olusturulamaz.
NAMING_CONVENTION = {
    "ix": "ix_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Tum ORM modellerinin miras aldigi taban sinif.

    Alembic tablolari bu sinifin metadata'sindan okur.
    """

    metadata = MetaData(naming_convention=NAMING_CONVENTION)