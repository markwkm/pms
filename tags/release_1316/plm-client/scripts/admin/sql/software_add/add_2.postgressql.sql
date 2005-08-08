INSERT INTO plm_software (id, rsf, created, deleted, name, description)
VALUES (3, 1, "","",'postgresql', 'PostgreSQL base source tree');


INSERT INTO plm_source(id , rsf, created , deleted, plm_software_id, plm_source_type,root_location, source_password, sc_module, sc_branch)
VALUES (3, 1, "" ,"", 3, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/postgresql',NULL,NULL,NULL);

INSERT INTO plm_source_sync (id , rsf, created, modified, plm_source_id, search_location, depth, wanted_regex, not_wanted_regex, baseline, applies_regex, name_substitution, descriptor, last_timestamp)
VALUES (0,1,NOW(),NULL, 3, '', 1, 'postgresql-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'PostgeSQL Local Base','');


INSERT INTO plm_command_set VALUES (2, 'postgresql', 'build');
INSERT INTO plm_command_set VALUES (3, 'postgresql', 'install');
INSERT INTO plm_software_to_command_set VALUES (0, 3, 2, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 3, 3, 0, 9999999999);

INSERT INTO plm_command  VALUES ( 5,2,0,'./configure --prefix=/usr/local','command',0);
INSERT INTO plm_command  VALUES ( 6,2,1,'gmake','command',0);
INSERT INTO plm_command  VALUES ( 7,3,2,'gmake install','command',0);
INSERT INTO plm_command  VALUES ( 8,3,3,'adduser postgres','command',0);
#INSERT INTO plm_command  VALUES ( 9,3,6,'mkdir -p -m 0222 /usr/local/pgsql/data','command',0);
#INSERT INTO plm_command  VALUES ( 10,3,7,'chown postgres:postgres /usr/local/pgsql/data','command',0);
#INSERT INTO plm_command  VALUES ( 11,3,8,'su - postgres -c \'/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data\'','command',0);
#INSERT INTO plm_command  VALUES ( 12,3,9,'su - postgres -c \'/usr/local/pgsql/bin/postmaster -D /usr/local/pgsql/data\'','command',0);
#INSERT INTO plm_command  VALUES ( 13,3,10,'su - postgres -c \'/usr/local/pgsql/bin/createdb  -D /usr/local/pgsql/data test\'','command',0);
#INSERT INTO plm_command  VALUES ( 14,3,11,'su - postgres -c \'/usr/local/pgsql/bin/psql  -D /usr/local/pgsql/data test\'','command',0);

INSERT INTO plm_patch_acl (id, plm_software_id, name, reason, regex)
VALUES (7, 3, 'PostgreSQL Base', 'Conflicts with the PostgreSQL base tree', '^postgresql-\d+.\d+$');

INSERT INTO plm_patch_acl_to_user(id, plm_patch_acl_id, plm_user_id)
VALUES (7, 7, 15);

