from sqlalchemy import Binary, Column, Integer, String
from sqlalchemy.orm import relation
from sqlalchemy.schema import ForeignKey

from pms.model.meta import Base

class Filter(Base):

    __tablename__ = 'filters'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    software_id = Column('software_id', ForeignKey('softwares.id'))
    name = Column('name', String, nullable=False)
    filename = Column('filename', String, nullable=False)
    runtime = Column('runtime', Integer)
    filter_type_id = Column('filter_type_id', Integer, nullable=False)
    file = Column('file', Binary)

    software = relation('Software', foreign_keys="Software.id", uselist=False)
