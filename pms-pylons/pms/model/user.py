from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relation, backref

from pms.model.meta import Base

class User(Base):

    __tablename__ = 'users'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    login = Column('login', String, unique=True, nullable=False)
    first = Column('first', String)
    last = Column('last', String)
    email = Column('email', String)
    password = Column('password', String)
    admin = Column('admin', Boolean, nullable=False, default=False)

    patches = relation('Patch', backref=backref('user'))
