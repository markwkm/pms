from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relation, backref

from pms.model.meta import Base

class Software(Base):

    __tablename__ = 'softwares'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    name = Column('name', String, unique=True, nullable=False)
    description = Column('description', String)
    default_strip_level = Column('default_strip_level', Integer)

    patches = relation('Patch')
