"""The application's model objects"""
import sqlalchemy as sa
from sqlalchemy import orm

from pms.model import meta
from sqlalchemy import schema, types

def init_model(engine):
    """Call me before using any of the tables or classes in the model"""
    ## Reflected tables must be defined and mapped here
    #global reflected_table
    #reflected_table = sa.Table("Reflected", meta.metadata, autoload=True,
    #                           autoload_with=engine)
    #orm.mapper(Reflected, reflected_table)
    #
    meta.Session.configure(bind=engine)
    meta.engine = engine


## Non-reflected tables may be defined and mapped at module level
#foo_table = sa.Table("Foo", meta.metadata,
#    sa.Column("id", sa.types.Integer, primary_key=True),
#    sa.Column("bar", sa.types.String(255), nullable=False),
#    )
#
#class Foo(object):
#    pass
#
#orm.mapper(Foo, foo_table)

softwares_table = schema.Table('softwares', meta.metadata,
        schema.Column('id', types.Integer, schema.Sequence('softwares_id_seq',
                optional=True), primary_key=True),
        schema.Column('name', types.Text()),
        schema.Column('description', types.Text()),
        schema.Column('default_strip_level', types.Integer),
)

sources_table = schema.Table('sources', meta.metadata,
        schema.Column('id', types.Integer, schema.Sequence('sources_id_seq',
                optional=True), primary_key=True),
        schema.Column('software_id', types.Integer,
                schema.ForeignKey('softwares.id')),
        schema.Column('root_location', types.Text()),
        schema.Column('source_type', types.Text()),
)

source_syncs_table = schema.Table('source_syncs', meta.metadata,
        schema.Column('id', types.Integer,
                schema.Sequence('source_syncs_id_seq',
                optional=True), primary_key=True),
        schema.Column('source_id', types.Integer,
                schema.ForeignKey('sources.id')),
        schema.Column('search_location', types.Text()),
        schema.Column('depth', types.Integer),
        schema.Column('wanted_regex', types.Text()),
        schema.Column('not_wanted_regex', types.Text()),
        schema.Column('baseline', types.BOOLEAN),
        schema.Column('applies_regex', types.Text()),
        schema.Column('name_substitution', types.Text()),
        schema.Column('descriptor', types.Text()),
)

class Software(object):
    pass

class Source(object):
    pass

class SourceSync(object):
    pass

orm.mapper(Software, softwares_table, properties={
        'sources': orm.relation(Source, backref='software')})

orm.mapper(Source, sources_table,properties={
        'syncs': orm.relation(SourceSync, backref='source')})

orm.mapper(SourceSync, source_syncs_table)

## Classes for reflected tables may be defined here, but the table and
## mapping itself must be done in the init_model function
#reflected_table = None
#
#class Reflected(object):
#    pass
