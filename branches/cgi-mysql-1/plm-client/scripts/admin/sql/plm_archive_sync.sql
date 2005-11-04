# Table:  plm_archive
# Purpose: This table tracks all the remote archives that need syncing into PLM.
#     Each type of file to be collected will have one line here.
#
#
#  New methods ASP::ArchiveFile, PLM::ArchiveFile to access this data
#
#These were moved to be in table plm_source
#ALTER TABLE plm_software ADD COLUMN location varchar(255);
#ALTER TABLE plm_software ADD COLUMN archive_type varchar(25);

#UPDATE plm_software set location='http://mirrors/ftp.kernel.org/pub/linux/kernel', repo_type='URL' where id=1;
#DROP TABLE plm_archive;

CREATE TABLE plm_archive(
    id       INT                  NOT NULL PRIMARY KEY AUTO_INCREMENT,
    rsf INT,
    created date,
    modified date,
    plm_software_id INT           NOT NULL,
    #archive_type  VARCHAR(25)            NOT NULL,
    #location  VARCHAR(255)       NOT NULL,
    directory  VARCHAR(255)      NOT NULL,
    depth   INTEGER               NOT NULL DEFAULT '0',
    wanted_regex  VARCHAR(255)   NOT NULL,
    not_wanted_regex  VARCHAR(255),
    baseline  VARCHAR(1)         NOT NULL DEFAULT 'N',
    applies_regex     VARCHAR(255),
    name_substitution   VARCHAR(255),
    descriptor  VARCHAR(255)
);

#
#  Here are the current values for production
#
# Base Kernels
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'v2.4', 0, 'linux-2.4.\\d+','(\^linux-)?!|test|prerelease','Y', NULL, '', 'Base 2.4 kernel');
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'v2.4/testing', 0, 'patch-2.4.\\d+-(pre|rc)\\d+','','N', 's/(2\\.4\\.)(\\d+)-(pre|rc)\\d+/\"$1\".eval \"$2-1\"/e', '', 'Test 2.4 kernel');
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'v2.6', 0, 'linux-2.6.\\d+','(\^linux-)?!|prerelease','Y', NULL, '','Base 2.6 kernel');
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'v2.6/testing', 0, 'patch-2.6.\\d+-(pre|rc)\\d+','','N', 's/(2\\.6\\.)(\\d+)-(pre|rc)\\d+/\"$1\".eval \"$2-1\"/e', '', 'Test 2.6 kernel');
# These are the bk patches.
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'v2.6/snapshots', 0, '\^patch-(.*)-bk\\d+', '\^patch-2.6.0-(test[1-4]-bk|test5-bk[0-8])','N', '(2\\.6\\.\\d+-test\\d+|2\\.6\\.\\d+)', '', 'Linus BK patches');
# These are other peoples patches
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'people/alan/linux-2.4', 1, '(.*)-ac','','N', '\^patch-(\\d+\\.\\d+\\.\\d+\\-?.*)\\-ac\\d+$', '', 'ac Patches');
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'people/alan/linux-2.6', 1, '(.*)-ac','','N', '\^patch-(\\d+\\.\\d+\\.\\d+|2\\.6\\.\\d+\\-test\\d+)\\-ac\\d+$', '', 'ac Patches');
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'people/akpm/patches/2.6', 2, '(.*)-mm','','N', '\^(\\d+\\.\\d+\\.\\d+-rc\\d+|\\d+\\.\\d+\\.\\d+-test\\d+|\\d+\\.\\d+\\.\\d+)', '', 'Andrew Morton Patches');
#INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'people/mbligh', 1, 'patch-(.*)-mjb','patch-(.*)-bk\\d+','N', 'patch-(.*)-mjb', '', 'Martin Bligh Patches');
#INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'ports/ia64/v2.4', 0, '(.*)-ia64','','N', 'linux-(.*)-ia64', '/(.*)\\.diff/\$1/', 'ia64 Patches');
#INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'ports/ia64/v2.6', 0, '(.*)-ia64','','N', 'linux-(.*)-ia64', '/(.*)\\.diff/\$1/', 'ia64 Patches');
# These are osdl add-ins-  Currently only Redhat base kernels
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, '../../../../OSDL/PLM', 0, '','','Y', NULL, '/linux/redhat/', 'Locally generated Redhat Base Kernels');

#
# Here are the current values for testdev.
#
INSERT INTO plm_archive VALUES (0, 1, NOW(), NULL, 1, 'URL', 'http://mirrors.pdx.osdl.net/ftp.kernel.org/pub/linux/kernel', 'v2.4', 0, '','test|prerelease','Y', NULL, '', 'Base 2.4 kernel');

# Table:  plm_post_sync
# Purpose:  This table is where we store the commands which are executed after the sync.
#           These will be the 'eidetic_sync' and the 'mass_request.pl'.
#
CREATE TABLE plm_post_sync (
    id     INT    NOT NULL,
    rsf INT,
    created date,
    modified date,
    plm_archive_id   INT,
    plm_post_sync_command_id  INT
);
    

# Table:  plm_post_sync_command
# Purpose:  This table is where we store the commands which are executed after the sync.
#           These will be the 'eidetic_sync' and the 'mass_request.pl'.
#
CREATE TABLE plm_post_sync_command (
    id     INT    NOT NULL,
    rsf INT,
    created date,
    modified date,
    command VARCHAR2(256),
    config_file VARCHAR2(256),
    depend_filter_id INT,
    depend_filter_result VARCHAR2(255)
);

#
#
#
ALTER TABLE plm_patch ADD COLUMN plm_post_sync_id  INT ;
