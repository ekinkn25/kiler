from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Tum ORM modellerinin miras alacagi taban sinif.

    W1-T05'te yazilacak User, PantryItem gibi tum modeller bunu miras alir.
    Alembic de tablolari bu sinifin metadata'sindan okur.
    """