"""First revision

Revision ID: 2bdd878a3dc8
Revises: 
Create Date: 2022-03-10 10:31:00.529588

"""
from alembic import op
from sqlalchemy import create_engine
import sqlalchemy as sa

engine = create_engine('postgresql://materialize:materialize@localhost:6875/materialize')

# revision identifiers, used by Alembic.
revision = '2bdd878a3dc8'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    engine.execute('SHOW TABLES')
    # op.create_table('users',
    #                 sa.Column('id', sa.Integer(), nullable=False),
    #                 sa.Column('username', sa.String(length=80), nullable=False),
    #                 sa.Column('password', sa.String(length=80), nullable=False),
    #                 sa.PrimaryKeyConstraint('id'),
    #                 sa.UniqueConstraint('username')
    #                 )


def downgrade():
    op.drop_table('users')

