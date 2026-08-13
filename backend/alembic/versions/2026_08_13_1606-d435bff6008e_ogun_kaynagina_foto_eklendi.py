"""ogun kaynagina foto eklendi

Revision ID: d435bff6008e
Revises: 98414fbf66a1
Create Date: 2026-08-13 16:06:39.658847

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd435bff6008e'
down_revision: Union[str, Sequence[str], None] = '98414fbf66a1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('meal_logs', schema=None) as batch_op:
        batch_op.alter_column(
            'source',
            existing_type=sa.Enum('manuel', 'barkod', 'tarif',
                                  name='logsource', native_enum=False, create_constraint=True),
            type_=sa.Enum('manuel', 'foto', 'barkod', 'tarif',
                          name='logsource', native_enum=False, create_constraint=True),
            existing_nullable=False,
        )


def downgrade() -> None:
    with op.batch_alter_table('meal_logs', schema=None) as batch_op:
        batch_op.alter_column(
            'source',
            existing_type=sa.Enum('manuel', 'foto', 'barkod', 'tarif',
                                  name='logsource', native_enum=False, create_constraint=True),
            type_=sa.Enum('manuel', 'barkod', 'tarif',
                          name='logsource', native_enum=False, create_constraint=True),
            existing_nullable=False,
        )
