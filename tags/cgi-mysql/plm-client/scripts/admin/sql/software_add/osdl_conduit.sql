INSERT INTO plm_source_sync VALUES (10,1,'2004-07-09',NULL,1,'../../../../OSDL/PLM/osdl_conduit',0,'^osdl-(\\d+\.\\d+\.\\d+)','','N',NULL,'','OSDL Conduit Patch Set');

INSERT INTO plm_patch_acl (id, plm_software_id, name, reason, regex)
VALUES (4, 1, 'OSDL Conduit', 'Conflicts with the OSDL Conduit', '^osdl-\\d+\.\\d+\.\\d+$');

INSERT INTO plm_patch_acl_to_user(id, plm_patch_acl_id, plm_user_id)
VALUES (4, 4, 15);


INSERT INTO plm_patch_acl (id, plm_software_id, name, reason, regex)
VALUES (5, 1, 'Mm Conduit', 'Conflicts with the Andrew Morton Conduit', '^\\d+\.\\d+\.\\d+-mm\\d+$');

INSERT INTO plm_patch_acl_to_user(id, plm_patch_acl_id, plm_user_id)
VALUES (5, 5, 15);

