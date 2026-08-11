"""kiler modeli: guven durumu ve kaynak

Revision ID: f7a3a08b9ed7
Revises: a5f119801c2a
Create Date: 2026-08-11 11:30:06.240661
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f7a3a08b9ed7"
down_revision: Union[str, Sequence[str], None] = "a5f119801c2a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Model ile birebir ayni tipler: enum_col(...) native_enum=False +
# create_constraint=True uretiyor. Duz sa.String kullanirsak CHECK kisiti
# olusmaz ve autogenerate her seferinde fark bulur.
availability_type = sa.Enum(
    "var", "bilinmiyor", "bitti",
    name="availability", native_enum=False, create_constraint=True,
)
source_type = sa.Enum(
    "barkod", "foto", "tarif", "sistem",
    name="pantrysource", native_enum=False, create_constraint=True,
)


def upgrade() -> None:
    # Sutunlari dusurmeden ONCE uzerlerindeki indeksler kaldirilmali.
    op.drop_index("ix_pantry_expiry", table_name="pantry_items")
    op.drop_index("ix_pantry_user_active", table_name="pantry_items")

    with op.batch_alter_table("pantry_items", schema=None) as batch_op:
        # ---------- YENI: inanc durumu ----------
        # server_default: mevcut satirlarin bir degeri olmali. Eski kayitlarin
        # ne zaman eklendigini bilmedigimiz icin 'bilinmiyor' durusu durust.
        batch_op.add_column(sa.Column(
            "availability", availability_type, nullable=False,
            server_default="bilinmiyor",
        ))
        batch_op.add_column(sa.Column(
            "source", source_type, nullable=False, server_default="sistem",
        ))
        batch_op.add_column(sa.Column("confirmed_at", sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column("confidence_expires_at", sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column("detected_confidence", sa.Float(), nullable=True))

        # ---------- Miktar artik opsiyonel ----------
        batch_op.alter_column("quantity_base", existing_type=sa.FLOAT(), nullable=True)
        batch_op.alter_column("unit_type", existing_type=sa.VARCHAR(6), nullable=True)
        batch_op.alter_column("display_unit", existing_type=sa.VARCHAR(12), nullable=True)

        # ---------- Yeni indeksler ----------
        batch_op.create_index("ix_pantry_confidence_expiry",
                              ["confidence_expires_at"], unique=False)
        batch_op.create_index("ix_pantry_user_availability",
                              ["user_id", "availability"], unique=False)

        # ---------- Kisitlar ----------
        batch_op.create_check_constraint(
            "quantity_nonnegative", "quantity_base IS NULL OR quantity_base >= 0")
        batch_op.create_check_constraint(
            "confidence_range",
            "detected_confidence IS NULL OR "
            "(detected_confidence >= 0 AND detected_confidence <= 1)")

        # ---------- Kapsam disi kalan alanlar ----------
        batch_op.drop_column("min_threshold_base")   # esik otomasyonu kesildi
        batch_op.drop_column("expiry_date")          # SKT takibi kesildi
        batch_op.drop_column("opened_at")            # SKT takibi kesildi
        batch_op.drop_column("is_active")            # availability='bitti' devraldi
        batch_op.drop_column("custom_name")          # elle giris kalkti
        batch_op.drop_column("last_restocked_at")    # confirmed_at devraldi

    # server_default yalnizca mevcut satirlari doldurmak icindi.
    # Bundan sonra degeri uygulama kodu belirlesin.
    with op.batch_alter_table("pantry_items", schema=None) as batch_op:
        batch_op.alter_column("availability", existing_type=availability_type,
                              server_default=None)
        batch_op.alter_column("source", existing_type=source_type,
                              server_default=None)


def downgrade() -> None:
    op.drop_index("ix_pantry_user_availability", table_name="pantry_items")
    op.drop_index("ix_pantry_confidence_expiry", table_name="pantry_items")

    # NOT NULL'a geri donmeden once NULL kalmis satirlari doldur,
    # yoksa 'NOT NULL constraint failed' alinir.
    op.execute("UPDATE pantry_items SET quantity_base = 0 WHERE quantity_base IS NULL")
    op.execute("UPDATE pantry_items SET unit_type = 'mass' WHERE unit_type IS NULL")
    op.execute("UPDATE pantry_items SET display_unit = 'g' WHERE display_unit IS NULL")

    with op.batch_alter_table("pantry_items", schema=None) as batch_op:
        # Eski alanlari server_default ile geri ekle (mevcut satirlar icin sart)
        batch_op.add_column(sa.Column("min_threshold_base", sa.FLOAT(),
                                      nullable=False, server_default="0"))
        batch_op.add_column(sa.Column("expiry_date", sa.DATE(), nullable=True))
        batch_op.add_column(sa.Column("opened_at", sa.DATE(), nullable=True))
        batch_op.add_column(sa.Column("is_active", sa.BOOLEAN(),
                                      nullable=False, server_default="1"))
        batch_op.add_column(sa.Column("custom_name", sa.VARCHAR(length=150), nullable=True))
        batch_op.add_column(sa.Column("last_restocked_at", sa.DATETIME(), nullable=True))

        batch_op.drop_constraint("ck_pantry_items_confidence_range", type_="check")
        batch_op.drop_constraint("ck_pantry_items_quantity_nonnegative", type_="check")

        batch_op.drop_column("detected_confidence")
        batch_op.drop_column("confidence_expires_at")
        batch_op.drop_column("confirmed_at")
        batch_op.drop_column("source")
        batch_op.drop_column("availability")

        batch_op.alter_column("quantity_base", existing_type=sa.FLOAT(), nullable=False)
        batch_op.alter_column("unit_type", existing_type=sa.VARCHAR(6), nullable=False)
        batch_op.alter_column("display_unit", existing_type=sa.VARCHAR(12), nullable=False)

        batch_op.create_index("ix_pantry_user_active", ["user_id", "is_active"], unique=False)
        batch_op.create_index("ix_pantry_expiry", ["expiry_date"], unique=False)