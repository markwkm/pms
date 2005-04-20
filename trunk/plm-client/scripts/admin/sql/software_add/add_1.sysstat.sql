INSERT INTO plm_software (id, rsf, created, deleted, name, description)
VALUES (2, 1, "","",'sysstat', 'Sysstat Base Source');

INSERT INTO plm_source VALUES (2, 1, "" ,"", 2, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/sysstat',NULL,NULL,NULL);

INSERT INTO plm_source_sync VALUES (10,1,NOW(),NULL, 2, 'v4', 1, 'sysstat-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'Sysstat Version 4 Base','');

INSERT INTO plm_source_sync VALUES (11,1,NOW(),NULL, 2, 'v5', 1, 'sysstat-\\d+\.\\d+', NULL, 'Y', NULL, NULL, 'Sysstat Version 5 Base','');


#Set up build command sets for sysstat

INSERT INTO plm_command_set VALUES (6, 'sysstat', 'build');
INSERT INTO plm_command_set VALUES (7, 'sysstat', 'install');

# Sysstat ties to 'sysstat' build and install
INSERT INTO plm_software_to_command_set VALUES (0, 2, 6, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 2, 7, 0, 9999999999);

# here are the commands
INSERT INTO plm_command  VALUES ( 12,6,0,' echo \'






\' | make config','command',0);
INSERT INTO plm_command  VALUES ( 13,6,1,'make','command',0);
INSERT INTO plm_command  VALUES ( 14,7,2,'make install','command',0);


INSERT INTO plm_patch_acl (id, plm_software_id, name, reason, regex)
VALUES (6, 2, 'Sysstat Base', 'Conflicts with the Sysstat base tree', '^sysstat-\d+.\d+$');

INSERT INTO plm_patch_acl_to_user(id, plm_patch_acl_id, plm_user_id)
VALUES (6, 6, 15);

# This makes 'applies' filter run for all type of software.
UPDATE plm_filter set plm_software_id = 0 where id=1;
