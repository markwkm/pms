--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: command_sets; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE command_sets (
    id bigserial NOT NULL,
    name text NOT NULL,
    command_set_type text NOT NULL
);


--
-- Name: command_sets_softwares; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE command_sets_softwares (
    software_id bigint NOT NULL,
    command_set_id bigint NOT NULL,
    min_patch_id bigint DEFAULT 0 NOT NULL,
    max_patch_id bigint DEFAULT 9223372036854775807::bigint NOT NULL
);


--
-- Name: commands; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE commands (
    id bigserial NOT NULL,
    command_set_id bigint NOT NULL,
    command_order smallint NOT NULL,
    command text NOT NULL,
    command_type text NOT NULL,
    expected_result text
);


--
-- Name: filter_request_states; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE filter_request_states (
    code text NOT NULL,
    detail text
);


--
-- Name: filter_requests; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE filter_requests (
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


--
-- Name: filter_types; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE filter_types (
    id bigserial NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    code text NOT NULL,
    software_id bigint
);


--
-- Name: filters; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE filters (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    software_id bigint NOT NULL,
    name text NOT NULL,
    command text,
    "location" text,
    runtime bigint,
    filter_type_id bigint NOT NULL
);


--
-- Name: patch_acls; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE patch_acls (
    id bigserial NOT NULL,
    software_id bigint NOT NULL,
    name text NOT NULL,
    reason text,
    regex text NOT NULL
);


--
-- Name: patch_acls_users; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE patch_acls_users (
    patch_acl_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: patches; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

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
    strip_level smallint NOT NULL,
    source_id bigint,
    reverse boolean DEFAULT false NOT NULL,
    remote_identifier text,
    path text
);


SET default_with_oids = true;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE sessions (
    id serial NOT NULL,
    session_id character varying(255),
    data text,
    updated_at timestamp without time zone
);


SET default_with_oids = false;

--
-- Name: softwares; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE softwares (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    description text
);


--
-- Name: sources; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE sources (
    id bigserial NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    updated_on timestamp with time zone DEFAULT now() NOT NULL,
    software_id bigint NOT NULL,
    root_location text NOT NULL,
    source_type text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: plm; Tablespace: 
--

CREATE TABLE users (
    id bigserial NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    updated_on timestamp without time zone DEFAULT now(),
    login text NOT NULL,
    "first" text,
    "last" text,
    email text,
    "password" text
);


--
-- Name: command_sets_name_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY command_sets
    ADD CONSTRAINT command_sets_name_key UNIQUE (name, command_set_type);


--
-- Name: command_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY command_sets
    ADD CONSTRAINT command_sets_pkey PRIMARY KEY (id);


--
-- Name: command_sets_softwares_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY command_sets_softwares
    ADD CONSTRAINT command_sets_softwares_pkey PRIMARY KEY (software_id, command_set_id);


--
-- Name: commands_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY commands
    ADD CONSTRAINT commands_pkey PRIMARY KEY (id);


--
-- Name: filter_request_states_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filter_request_states
    ADD CONSTRAINT filter_request_states_pkey PRIMARY KEY (code);


--
-- Name: filter_requests_filter_id_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filter_requests
    ADD CONSTRAINT filter_requests_filter_id_key UNIQUE (filter_id, patch_id);


--
-- Name: filter_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filter_requests
    ADD CONSTRAINT filter_requests_pkey PRIMARY KEY (id);


--
-- Name: filter_types_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filter_types
    ADD CONSTRAINT filter_types_pkey PRIMARY KEY (id);


--
-- Name: filters_name_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_name_key UNIQUE (name);


--
-- Name: filters_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_pkey PRIMARY KEY (id);


--
-- Name: patch_acls_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY patch_acls
    ADD CONSTRAINT patch_acls_pkey PRIMARY KEY (id);


--
-- Name: patch_acls_users_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY patch_acls_users
    ADD CONSTRAINT patch_acls_users_pkey PRIMARY KEY (patch_acl_id, user_id);


--
-- Name: patches_name_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY patches
    ADD CONSTRAINT patches_name_key UNIQUE (name);


--
-- Name: patches_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY patches
    ADD CONSTRAINT patches_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: softwares_name_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY softwares
    ADD CONSTRAINT softwares_name_key UNIQUE (name);


--
-- Name: softwares_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY softwares
    ADD CONSTRAINT softwares_pkey PRIMARY KEY (id);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: users_login_key; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: plm; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: sessions_session_id_index; Type: INDEX; Schema: public; Owner: plm; Tablespace: 
--

CREATE INDEX sessions_session_id_index ON sessions USING btree (session_id);


--
-- Name: command_sets_softwares_command_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY command_sets_softwares
    ADD CONSTRAINT command_sets_softwares_command_set_id_fkey FOREIGN KEY (command_set_id) REFERENCES command_sets(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: command_sets_softwares_software_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY command_sets_softwares
    ADD CONSTRAINT command_sets_softwares_software_id_fkey FOREIGN KEY (software_id) REFERENCES softwares(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: commands_command_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY commands
    ADD CONSTRAINT commands_command_set_id_fkey FOREIGN KEY (command_set_id) REFERENCES command_sets(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filter_requests_state_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filter_requests
    ADD CONSTRAINT filter_requests_state_fkey FOREIGN KEY (state) REFERENCES filter_request_states(code) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filter_types_software_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filter_types
    ADD CONSTRAINT filter_types_software_id_fkey FOREIGN KEY (software_id) REFERENCES softwares(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filters_filter_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_filter_type_id_fkey FOREIGN KEY (filter_type_id) REFERENCES filter_types(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filters_patches_filter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filter_requests
    ADD CONSTRAINT filters_patches_filter_id_fkey FOREIGN KEY (filter_id) REFERENCES filters(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filters_patches_patch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filter_requests
    ADD CONSTRAINT filters_patches_patch_id_fkey FOREIGN KEY (patch_id) REFERENCES patches(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: filters_software_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY filters
    ADD CONSTRAINT filters_software_id_fkey FOREIGN KEY (software_id) REFERENCES softwares(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: patch_acls_software_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY patch_acls
    ADD CONSTRAINT patch_acls_software_id_fkey FOREIGN KEY (software_id) REFERENCES softwares(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: patch_acls_users_patch_acl_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY patch_acls_users
    ADD CONSTRAINT patch_acls_users_patch_acl_id_fkey FOREIGN KEY (patch_acl_id) REFERENCES patch_acls(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: patch_acls_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY patch_acls_users
    ADD CONSTRAINT patch_acls_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: patches_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY patches
    ADD CONSTRAINT patches_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: sources_software_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: plm
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_software_id_fkey FOREIGN KEY (software_id) REFERENCES softwares(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

