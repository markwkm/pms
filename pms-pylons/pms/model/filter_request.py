from sqlalchemy import Binary, Column, Date, Integer, SmallInteger, String
from sqlalchemy.orm import relation
from sqlalchemy.schema import ForeignKey

from pms.model.meta import Base

class FilterRequest(Base):

    __tablename__ = 'filter_requests'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    filter_id = Column('filter_id', ForeignKey('filters.id'))
    patch_id = Column('patch_id', ForeignKey('patches.id'))
    priority = Column('priority', SmallInteger, nullable=False)
    result = Column('result', String)
    result_detail = Column('result_detail', String)
    output = Column('output', Binary)
    updated_on = Column('updated_on', Date)
    state = Column('state', ForeignKey('filter_request_states.code'))

    filter = relation('Filter', foreign_keys="Filter.id", uselist=False)
