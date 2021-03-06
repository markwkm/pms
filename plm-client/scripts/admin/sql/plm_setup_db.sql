
CREATE TABLE plm_user(
	id INT,
	rsf INT,
	created INT,
	deleted INT,
	modified INT,
	accessed INT,
	name VARCHAR(80),
	pass VARCHAR(254),
	gpgkey BLOB,
	email VARCHAR(150),
	admin_flag INT,
	stp_flag INT,
	autosubmit_flag INT,
	autopublic_flag INT,
	KEY (name),
	KEY (email)
);

CREATE TABLE plm_patch(
	id INT NOT NULL,
	rsf INT,
	created INT,
	deleted INT,
	modified INT,
	accessed INT,
	plm_user_id INT,
	plm_software_id INT,
	name VARCHAR(200),
	private_flag INT,
	submit_flag INT,
	md5sum VARCHAR(100),
        patch_path varchar(255) default NULL,
        remote_identifier varchar(255) default NULL,
        plm_source_id int(11) NOT NULL default '0',
        plm_applies_id int(11) default NULL,
        reverse INT,
	PRIMARY KEY (id),
	KEY (rsf),
	KEY (accessed),
	KEY (plm_user_id),
	KEY (plm_software_id),
	KEY (name)
);

CREATE TABLE plm_filter(
	id INT NOT NULL AUTO_INCREMENT,
	rsf INT,
	created INT,
	deleted INT,
	modified INT,
	accessed INT,
	plm_software_id INT,
	plm_filter_type_id INT,
	name VARCHAR(100) UNIQUE,
	location VARCHAR(254),
	command VARCHAR(254),
	runtime INT,
	PRIMARY KEY (id)
);

CREATE TABLE plm_filter_type(
    id INT NOT NULL AUTO_INCREMENT,
	rsf INT,
	created INT,
	modified INT,
	code VARCHAR(254) UNIQUE,
	plm_software_id INT,
	PRIMARY KEY (id)
);

CREATE TABLE plm_filter_request(
	id INT,
	created INT,
	modified INT,
	accessed INT,
	started INT,
	completed INT,
	plm_filter_id INT,
	plm_patch_id INT,
	plm_user_id INT,
	plm_filter_request_state_id INT,
	priority INT,
	result VARCHAR(4),
	result_detail VARCHAR(254),
	output TEXT
);

CREATE TABLE plm_filter_request_state(
	id INT,
	rsf INT,
	created INT,
	deleted INT,
	modified INT,
	code VARCHAR(254),
	detail TEXT
);

CREATE TABLE plm_group(
	id INT,
	rsf INT,
	created INT,
	deleted INT,
	modified INT,
	accessed INT,
	plm_private_flag INT,
	name VARCHAR(40)
);

CREATE TABLE plm_user_to_group(
	id INT,
	created INT,
	plm_user_id INT,
	plm_group_id INT,
	rev_flag INT
);

CREATE TABLE plm_software(
	id INT NOT NULL AUTO_INCREMENT,
	rsf INT,
	created INT,
	deleted INT,
	name VARCHAR(50) UNIQUE,
        description TEXT,
	PRIMARY KEY (id)
);

CREATE TABLE plm_source
(id     INT   NOT NULL auto_increment,
rsf INT(11) default NULL,
created INT(11) default NULL,
deleted INT(11) default NULL,
plm_software_id INT(11) NOT NULL,
plm_source_type VARCHAR(20) NOT NULL,
root_location   VARCHAR(255) NOT NULL,
source_password  VARCHAR(30) default NULL,
sc_module  VARCHAR(50) default NULL,
sc_branch  VARCHAR(50) default NULL,
PRIMARY KEY  (id)
);

CREATE TABLE plm_source_sync (
  id int(11) NOT NULL auto_increment,
  rsf int(11) default NULL,
  created date default NULL,
  modified date default NULL,
  plm_source_id int(11) NOT NULL default '0',
  search_location varchar(255) default NULL,
  depth int(11) NOT NULL default '0',
  wanted_regex varchar(255) default NULL,
  not_wanted_regex varchar(255) default NULL,
  baseline char(1) NOT NULL default 'N',
  applies_regex varchar(255) default NULL,
  name_substitution varchar(255) default NULL,
  descriptor varchar(100) default NULL,
  last_timestamp varchar(255) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

CREATE TABLE plm_command_set(
    id      INT NOT NULL auto_increment,
    name    VARCHAR(25) NOT NULL,
    command_set_type      VARCHAR(25),
    PRIMARY KEY  (id)
);

CREATE TABLE plm_command(
    id                   INT NOT NULL auto_increment,
    plm_command_set_id   INT,
    command_order        INT,
    command          TEXT,
    command_type     VARCHAR(25),
    expected_result  VARCHAR(255),
    PRIMARY KEY  (id)
);

CREATE TABLE plm_software_to_command_set(
    id                    INT NOT NULL auto_increment,
    plm_software_id       INT,
    plm_command_set_id    INT,
    min_plm_patch_id      INT,
    max_plm_patch_id      INT,
    PRIMARY KEY  (id)
);

CREATE TABLE plm_keyword(
	id INT,
	rsf INT,
	created INT,
	deleted INT,
	accessed INT,
	name VARCHAR(40)
);

CREATE TABLE plm_patch_to_keyword(
	id INT,
	plm_keyword_id INT,
	plm_patch_id INT
);

CREATE TABLE plm_index(
	token VARCHAR(254),
	lock_key VARCHAR(10),
	value INT
);

CREATE TABLE plm_patch_acl(
	id INT,
	plm_software_id INT,
	name VARCHAR(254),
	reason VARCHAR(254),
	regex VARCHAR(254)
);

CREATE TABLE plm_patch_acl_to_user(
	id INT,
	plm_patch_acl_id INT,
	plm_user_id INT
);
	

INSERT INTO plm_index (token) VALUES ('plm_user');
INSERT INTO plm_index (token) VALUES ('plm_patch');
INSERT INTO plm_index (token) VALUES ('plm_filter');
INSERT INTO plm_index (token) VALUES ('plm_filter_request');
INSERT INTO plm_index (token) VALUES ('plm_filter_request_state');
INSERT INTO plm_index (token) VALUES ('plm_group');
INSERT INTO plm_index (token) VALUES ('plm_user_to_group');
INSERT INTO plm_index (token) VALUES ('plm_software');
INSERT INTO plm_index (token) VALUES ('plm_keyword');
INSERT INTO plm_index (token) VALUES ('plm_patch_to_keyword');

UPDATE plm_index SET value = 0, lock_key = 'unused';

INSERT INTO plm_software (id, rsf, name) VALUES (1, 1, 'linux'); 
UPDATE plm_index SET value = 1 WHERE token = 'plm_software';

INSERT INTO plm_filter_request_state (id, code, detail) VALUES (1, 'Queued', 'The request is in the queue and no action has been taken.');
INSERT INTO plm_filter_request_state (id, code, detail) VALUES (2, 'Pending', 'The environment to handle the request is being prepared.');
INSERT INTO plm_filter_request_state (id, code, detail) VALUES (3, 'Running', 'Execution of the filter request is in progress.');
INSERT INTO plm_filter_request_state (id, code, detail) VALUES (4, 'Completed', 'Execution of the filter request has been completed.');
INSERT INTO plm_filter_request_state (id, code, detail) VALUES (5, 'Canceled', 'This filter request has been canceled.');
INSERT INTO plm_filter_request_state (id, code, detail) VALUES (6, 'Failed', 'An internal failure has kept the request from finishing.');
