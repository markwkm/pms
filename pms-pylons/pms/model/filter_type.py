from sqlalchemy import Column, Integer, String
from sqlalchemy.schema import ForeignKey

from pms.model.meta import Base

class FilterType(Base):

    __tablename__ = 'filter_types'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    software_id = Column('software_id', ForeignKey('softwares.id'))
    code = Column('code', String, nullable=False)
