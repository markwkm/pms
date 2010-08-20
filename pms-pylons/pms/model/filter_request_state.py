from sqlalchemy import Column, String

from pms.model.meta import Base

class FilterRequestState(Base):

    __tablename__ = 'filter_request_states'

    code = Column('code', String, primary_key=True)
    detail = Column('detail', String)
