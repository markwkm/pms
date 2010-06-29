INSERT INTO plm_command_set VALUES (2, 'postgresql', 'build');
INSERT INTO plm_command_set VALUES (3, 'postgresql', 'install');
INSERT INTO plm_software_to_command_set VALUES (0, 15, 2, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 15, 3, 0, 9999999999);

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
