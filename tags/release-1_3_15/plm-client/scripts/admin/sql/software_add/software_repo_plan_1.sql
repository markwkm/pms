
-systat ( bk repo is already on developer, also albert + goddard's versions as baselines )

INSERT INTO plm_software VALUES (2, 1, "","",'sysstat');
INSERT INTO plm_source VALUES (2, 1, "" ,"", 2, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/sysstat',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (10,1,NOW(),NULL, 2, 'v4', 1, 'sysstat-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'Sysstat Local Base','');
INSERT INTO plm_source_sync VALUES (11,1,NOW(),NULL, 2, 'v5', 1, 'sysstat-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'Sysstat Local Base','');


-oprofile - pull from oprofile CVS - changes frequently

INSERT INTO plm_software VALUES (5, 1, "","",'oprofile');
INSERT INTO plm_source VALUES (7, 1, "" ,"", 5, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/oprofile',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (18,1,NOW(),NULL, 7, NULL, 1, 'oprofile-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'Oprofile Local Base','');
#INSERT INTO plm_source VALUES (7, 1, "" ,"", 5, 'TAR', 'http://prdownloads.sourceforge.net/oprofile/',NULL,NULL,NULL);
#INSERT INTO plm_source_sync VALUES (17,NOW(),NULL, 7, NULL, 1, 'oprofile-\\d+-\\d+', 


-e2fsprogs - pull from CVS - changes seldom
INSERT INTO plm_software VALUES (6, 1, "","",'e2fsprogs');
INSERT INTO plm_source VALUES (8, 1, "" ,"", 6, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/e2fsprogs',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (19,1,NOW(),NULL, 8, NULL, 0, 'e2fsprogs-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'e2fsprogs Local Base','');



-xfwprogs - pull from CVS - changes seldom
INSERT INTO plm_software VALUES (7, 1, "","",'xfsprogs');
INSERT INTO plm_source VALUES (9, 1, "" ,"", 7, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/xfsprogs',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (20,1,NOW(),NULL, 9, NULL, 0, 'xfsprogs-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'xfsprogs Local Base','');



-jfsutils - pull from CVS - changes seldom
INSERT INTO plm_software VALUES (8, 1, "","",'jfsutils');
INSERT INTO plm_source VALUES (10, 1, "" ,"", 8, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/jfsutils',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (21,1,NOW(),NULL, 10, NULL, 0, 'jfsutils-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'jfsutils Local Base','');


-procps - Base line version, from alberto
INSERT INTO plm_software VALUES (5, 1, "","",'procps', 'The /proc file system utilities');
INSERT INTO plm_source VALUES (6, 1, "" ,"", 5, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/procps',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (0,1,NOW(),NULL, 6, NULL, 0, 'procps-\\d+\.\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'procps Local Base','');

- For Markw/dbt3
INSERT INTO plm_software VALUES (0, 1, "","",'dbt3-pgsql-sql', 'Customized files for dbt3');
INSERT INTO plm_source VALUES (0, 1, "" ,"", 4, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/dbt3-pgsql-sql',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (0,1,NOW(),NULL, 4, NULL, 0, 'dbt3-pgsql-sql(-\\d+)*', NULL, 'Y', NULL, NULL, 'dbt3-sql Base','');

-For Markw/dbt3
INSERT INTO plm_software VALUES (0, 1, "","",'pgsql-config', 'Customized config files for pgsql dbt tests');
INSERT INTO plm_source VALUES (0, 1, "" ,"", 5, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/pgsql-config',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (0,1,NOW(),NULL, 5, NULL, 0, 'pgsql-config(-\\d+\.\\d+)', NULL, 'Y', NULL, NULL, 'Config for pgsql dbt tests Base','');

-reiserfsprogs - pull from CVS - changes seldom.
INSERT INTO plm_software VALUES (10, 1, "","",'reiserfsprogs');
INSERT INTO plm_source VALUES (12, 1, "" ,"", 10, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/reiserfsprogs',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (23,1,NOW(),NULL, 12, NULL, 0, 'reiserfsprogs-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'reiserfsprogs Local Base','');

-reiser4progs - pull from CVS - changes seldom.
INSERT INTO plm_software VALUES (11, 1, "","",'reiser4progs');
INSERT INTO plm_source VALUES (13, 1, "" ,"", 11, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/reiser4progs',NULL,NULL,NULL);
INSERT INTO plm_source_sync VALUES (24,1,NOW(),NULL, 13, NULL, 0, 'reiser4progs-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'reiser4progs Local Base','');


INSERT INTO plm_command_set VALUES (4, 'basic', 'build');
INSERT INTO plm_command_set VALUES (5, 'basic', 'install');

# e2fsprogs ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 6, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 6, 5, 0, 9999999999);

# jfsprogs ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 8, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 8, 5, 0, 9999999999);

# xfsprogs ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 7, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 7, 5, 0, 9999999999);

# reiserfsprogs ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 10, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 10, 5, 0, 9999999999);

# reiser4progs ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 11, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 11, 5, 0, 9999999999);

# oprofile ties to 'basic' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 5, 4, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 5, 5, 0, 9999999999);

INSERT INTO plm_command  VALUES ( 9,4,0,'./configure','command',0);
INSERT INTO plm_command  VALUES ( 10,4,1,'make','command',0);
INSERT INTO plm_command  VALUES ( 11,5,2,'make install','command',0);

INSERT INTO plm_command_set VALUES (6, 'sysstat', 'build');
INSERT INTO plm_command_set VALUES (7, 'sysstat', 'install');

# Sysstat ties to 'sysstat' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 2, 6, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 2, 7, 0, 9999999999);

INSERT INTO plm_command  VALUES ( 12,6,0,' echo \'






\' | make config','command',0);
INSERT INTO plm_command  VALUES ( 13,6,1,'make','command',0);
INSERT INTO plm_command  VALUES ( 14,7,2,'make install','command',0);

#  Thes have id 9 and 10
INSERT INTO plm_command_set VALUES (0, 'procps', 'build');
INSERT INTO plm_command_set VALUES (0, 'procps', 'install');

# Sysstat ties to 'procps' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 5, 9, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 5, 10, 0, 9999999999);

INSERT INTO plm_command  VALUES ( 0,9,1,'make','command',0);
INSERT INTO plm_command  VALUES ( 0,10,2,'make install','command',0);

