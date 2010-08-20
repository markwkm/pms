from sqlalchemy import Binary, Boolean, Column, Date, Integer, SmallInteger, \
                       String
from sqlalchemy.orm import relation, backref
from sqlalchemy.schema import ForeignKey

from pms.model.meta import Base

class Patch(Base):

    __tablename__ = 'patches'

    id = Column('id', Integer, primary_key=True, autoincrement=True)
    created_on = Column('created_on', Date, nullable=False)
    software_id = Column('software_id', ForeignKey('softwares.id'))
    md5sum = Column('md5sum', String)
    patch_id = Column('patch_id', ForeignKey('patches.id'))
    name = Column('name', String, nullable=False)
    diff = Column('diff', Binary)
    user_id = Column('user_id', ForeignKey('users.id'))
    strip_level = Column('strip_level', SmallInteger)
    source_id = Column('source_id', ForeignKey('sources.id'))
    reverse = Column('reverse', Boolean, nullable=False, default=False)
    remote_identifier = Column('remote_identifier', String)
    path = Column('path', String)

    patch = relation('Patch', foreign_keys="Patch.id", uselist=False)
    software = relation('Software', foreign_keys="Software.id", uselist=False)
    filter_requests = relation('FilterRequest')
