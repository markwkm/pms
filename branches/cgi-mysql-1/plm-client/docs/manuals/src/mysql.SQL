DROP DATABASE plm;
CREATE DATABASE plm;
use plm;

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
	id INT,
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
        patch_path VARCHAR(255),
        remote_identifier VARCHAR(255),
	PRIMARY KEY (id),
	KEY (rsf),
	KEY (accessed),
	KEY (plm_user_id),
	KEY (plm_software_id),
	KEY (name)
);

CREATE TABLE plm_note(
	id INT,
	rsf INT,
	created INT,
	deleted INT,
	accessed INT,
	plm_user_id INT,
	plm_patch_id INT,
	plm_note_type_id INT,
	subject VARCHAR(255),
	content BLOB,
	PRIMARY KEY (id),
	KEY (rsf),
	KEY (plm_user_id),
	KEY (plm_patch_id),
	KEY (plm_note_type_id)
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
	PRIMARY KEY (id)
);

CREATE TABLE plm_applies(
	plm_patch_id INT,
	target_plm_patch_id INT
);

CREATE TABLE plm_obsoletes(
	plm_patch_id INT,
	target_plm_patch_id INT
);

CREATE TABLE plm_note_type(
	id INT,
	rsf INT,
	deleted INT,
	created INT,
	accessed INT,
	name VARCHAR(60)
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

