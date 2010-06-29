INSERT INTO plm_software (id, rsf, created, deleted, name, description)
VALUES (4, 1, "","",'glibc', 'GNU C Library source tree');


INSERT INTO plm_source(id , rsf, created , deleted, plm_software_id, plm_source_type,root_location, source_password, sc_module, sc_branch)
VALUES (4, 1, "" ,"", 4, 'TAR', 'http://mirrors.pdx.osdl.net/OSDL/PLM/gnu/glibc',NULL,NULL,NULL);

INSERT INTO plm_source_sync (id , rsf, created, modified, plm_source_id, search_location, depth, wanted_regex, not_wanted_regex, baseline, applies_regex, name_substitution, descriptor, last_timestamp)
VALUES (0,1,NOW(),NULL, 4, '', 0, 'glibc-2\.\\d+', NULL, 'Y', NULL, NULL, 'GNU C Library base source tree','');


INSERT INTO plm_command_set VALUES (2, 'glibc', 'build');
INSERT INTO plm_command_set VALUES (3, 'glibc', 'install');
INSERT INTO plm_software_to_command_set VALUES (0, 3, 2, 0, 9999999999);
INSERT INTO plm_software_to_command_set VALUES (0, 3, 3, 0, 9999999999);

INSERT INTO plm_command  VALUES ( 5,8,0,'mkdir build','command',0);
INSERT INTO plm_command  VALUES ( 6,8,1,'cd build','command',0);
INSERT INTO plm_command  VALUES ( 7,8,2,'ROOT=/usr/local','command',0);
INSERT INTO plm_command  VALUES ( 8,8,3,'KDIR=/root/linux','command',0);
INSERT INTO plm_command  VALUES ( 9,8,4,'../configure --prefix=$ROOT --disable-profile --enable-add-ons=nptl --with-tls --without-gd --with-headers=$KDIR/include --enable-kernel=2.6.8.1','command',0);
INSERT INTO plm_command  VALUES ( 10,8,5,'gmake','command',0);
INSERT INTO plm_command  VALUES ( 10,3,6,'gmake install','command',0);

INSERT INTO plm_patch_acl (id, plm_software_id, name, reason, regex)
VALUES (8, 4, 'GNU C Library Base', 'Conflicts with the GNU C Library base tree', '^glibc-\d+.\d+$');

INSERT INTO plm_patch_acl_to_user(id, plm_patch_acl_id, plm_user_id)
VALUES (9, 8, 15);

