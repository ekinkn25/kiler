from datetime import datetime

from sqlalchemy import DateTime, Enum as SAEnum, func
from sqlalchemy.orm import Mapped, mapped_column

class TimestampMixin: 
    """created_at / updated_at sütunlarını tüm modellere ekliyoruz"""
    created_at : Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at : Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

def enum_col(py_enum, **kwargs):
    """Python Enum'unu SQLite için VHARCHAR + CHECK sütununa çevirir.
    values_callable KRİTİK: bu olmadan SQLAlchemy üye adını ("KAHVALTI") saklar, değerini deği ('kahvalti'). API ve DB tutarsız hale gelir"""
    return mapped_column(
        SAEnum(
            py_enum,
            native_enum=False,
            create_constraint=True,
            validate_strings=True,
            name=f"ck_{py_enum.__name__.lower()}",
            values_callable=lambda e: [member.value for member in e],
        ),
        **kwargs
    )