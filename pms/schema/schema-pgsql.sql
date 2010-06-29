CREATE TABLE command_set (
    id bigserial NOT NULL,
    name text NOT NULL,
    command_set_type text NOT NULL,
    PRIMARY KEY (id)
);

-- max_patch_id is set to NULL until we know what patch the commands stop
-- being valid for.
CREATE TABLE software_command_set (
    software_id bigint NOT NULL,
    command_set_id bigint NOT NULL,
    min_patch_id bigint DEFAULT 0 NOT NULL,
    max_patch_id bigint DEFAULT NULL,
    PRIMARY KEY (software_id, command_set_id)
);

CREATE TABLE commands (
    id bigserial NOT NULL,
    command_set_id bigint NOT NULL,
    command_order smallint NOT NULL,
    command text NOT NULL,
    command_type text NOT NULL,
    expected_result text,
    PRIMARY KEY (id)
);

-- Table of 'state' names for what a client is doing.
CREATE TABLE client_states (
    code text NOT NULL,
    detail text,
    PRIMARY KEY (code)
);

CREATE TABLE results (
    filter_id bigint NOT NULL,
    patch_id bigint NOT NULL,
    priority smallint DEFAULT 1 NOT NULL,
    result text,
    result_detail text,
    output bytea,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    id bigserial NOT NULL,
    state text
);

CREATE TABLE filter_types (
    id bigserial NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    code text NOT NULL,
    software_id bigint
);

CREATE TABLE filters (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    software_id bigint NOT NULL,
    name text NOT NULL,
    filename text NOT NULL,
    runtime bigint,
    filter_type_id bigint NOT NULL,
    file bytea NOT NULL
);

CREATE TABLE patches (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    software_id bigint NOT NULL,
    md5sum character(40),
    patch_id bigint,
    name text NOT NULL,
    diff bytea,
    user_id bigint NOT NULL,
    strip_level smallint,
    source_id bigint,
    reverse boolean DEFAULT false NOT NULL,
    remote_identifier text,
    path text
);

CREATE TABLE software (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text,
    default_strip_level smallint NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE sources (
    id bigserial NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    software_id bigint NOT NULL,
    url text NOT NULL,
    source_type text NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE sources
ADD CONSTRAINT sources_software_id
FOREIGN KEY (software_id)
REFERENCES software (id);

CREATE TABLE source_filters (
    id bigserial NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    source_id bigint NOT NULL,
    search_location text,
    depth integer NOT NULL,
    wanted_regex text,
    not_wanted_regex text,
    baseline boolean NOT NULL,
    applies_regex text,
    name_substitution text,
    descriptor text,
    last_timestamp text,
    PRIMARY KEY (id)
);

CREATE TABLE users (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    login text NOT NULL,
    "first" text,
    "last" text,
    email text,
    "password" text,
    admin boolean DEFAULT false NOT NULL
);
