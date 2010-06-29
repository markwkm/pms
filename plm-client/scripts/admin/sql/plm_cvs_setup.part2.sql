# Database changes to add source specifications.
#

CREATE TABLE plm_source
(id     int   NOT NULL auto_increment,
rsf int(11) default NULL,
created int(11) default NULL,
deleted int(11) default NULL,
plm_software_id int(11) NOT NULL,
plm_source_type VARCHAR(20) NOT NULL,
root_location   VARCHAR(255) NOT NULL,
source_password  VARCHAR(30) default NULL,
sc_module  VARCHAR(50) default NULL,
sc_branch  VARCHAR(50) default NULL,
PRIMARY KEY  (id)
);

INSERT INTO plm_source VALUES(1, 0, NULL, NULL, 1, 'TAR', 'http://mirrors.pdx.osdl.org/ftp.kernel.org/pub/linux/kernel', NULL, NULL, NULL);
#Testdev only
#INSERT INTO plm_source VALUES(2, 0, NULL, NULL, 2, 'TAR', 'http://mirrors.pdx.osdl.org/OSDL/PLM/sysstat', NULL, NULL, NULL);
#INSERT INTO plm_source VALUES(4, 0, NULL, NULL, 2, 'TAR', 'http://perso.wanadoo.fr/sebastien.godard/', NULL, NULL, NULL);
#INSERT INTO plm_source VALUES(3, 0, NULL, NULL, 3, 'TAR', '', NULL, NULL, NULL);
#INSERT INTO plm_source_sync VALUES (0, 1, NOW(), NULL, 1, '/', 0, 'sysstat-4.\\d+','','Y', NULL, '', 'Base Systat');
#INSERT INTO plm_source_sync VALUES (0, 1, NOW(), NULL, 2, 'v4', 0, 'sysstat-4.\\d+','','Y', NULL, '', 'Local Base Systat');



ALTER TABLE plm_software DROP COLUMN location;
ALTER TABLE plm_software DROP COLUMN archive_type;

ALTER TABLE plm_patch add COLUMN plm_source_id INT;
UPDATE plm_patch SET plm_source_id = 1 WHERE remote_identifier != "";
UPDATE plm_patch SET plm_source_id = 0 WHERE remote_identifier = "";
UPDATE plm_patch SET plm_source_id = 0 WHERE remote_identifier IS NULL;
ALTER TABLE plm_patch MODIFY  COLUMN plm_source_id NOT NULL;



# This Part to be done manually...
#mysqldump -u mysql -p --tables plm_archive > /tmp/plm_archive.dmp
#cp /tmp/plm_archive.dmp create_plm_source_sync.sql

# Edit create_plm_source_sync.sql s/plm_archive/plm_source_sync/g

# In mysql again
#source create_plm_source_sync.sql



