from sqlalchemy import Column, Integer, String
from sqlalchemy.schema import ForeignKey

from pms.model.meta import Base

class Source(Base):

    __tablename__ = 'sources'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    software_id = Column('software_id', ForeignKey("softwares.id"))
    root_location = Column('root_location', String, nullable=False)
    source_type = Column('source_type', String, nullable=False)
