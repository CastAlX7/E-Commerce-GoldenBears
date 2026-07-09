"""add invoice status fields to billing_details

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-07-02 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e5f6a7b8c9d0'
down_revision: Union[str, Sequence[str], None] = 'd4e5f6a7b8c9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    invoice_status = sa.Enum('pending', 'issued', 'failed', name='invoice_status')
    invoice_status.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'billing_details',
        sa.Column('invoice_status', invoice_status, nullable=False, server_default='pending'),
    )
    op.add_column('billing_details', sa.Column('invoice_number', sa.String(length=50), nullable=True))
    op.add_column('billing_details', sa.Column('invoiced_at', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('billing_details', 'invoiced_at')
    op.drop_column('billing_details', 'invoice_number')
    op.drop_column('billing_details', 'invoice_status')
    sa.Enum(name='invoice_status').drop(op.get_bind(), checkfirst=True)
