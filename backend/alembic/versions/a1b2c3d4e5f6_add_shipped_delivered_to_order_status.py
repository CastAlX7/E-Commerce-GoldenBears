"""add shipped and delivered to order_status enum

Revision ID: a1b2c3d4e5f6
Revises: 3c0a86358b20
Create Date: 2026-06-09 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '3c0a86358b20'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'shipped'")
    op.execute("ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'delivered'")


def downgrade() -> None:
    # PostgreSQL no permite eliminar valores de un enum; la migración es irreversible
    pass
