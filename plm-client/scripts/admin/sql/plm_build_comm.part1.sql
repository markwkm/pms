#Storage of Build/Validation Information

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
    command_type     VARCHAR(25),         # This field will help to define how to handle 'expected_result'
    expected_result  VARCHAR(255),
    PRIMARY KEY  (id)
);


#
#Join Table
#    id                   int
#    software_type_id     int
#    build_set_id         int   foreign_key
#    validation_set_id    int   foreign_key
#    min_plm_patch_id     int   foreign_key
#    max_plm_patch_id     int   foreign_key
#
#
CREATE TABLE plm_software_to_command_set(
    id                    INT NOT NULL auto_increment,
    plm_software_id       INT,
    plm_command_set_id    INT,
    min_plm_patch_id      INT,
    max_plm_patch_id      INT,
    PRIMARY KEY  (id)
);


#These are test data
#INSERT INTO plm_command_set VALUES (0, 'robokern', 'build');
#INSERT INTO plm_software_to_command_set VALUES (0, 1, 1, 0, '');
#INSERT INTO plm_command VALUES (1, 1, 0, 'make defconfig', 'command', 0); 
#INSERT INTO plm_command VALUES (2, 1, 1, 'make bzImage', 'command', 0); 
#INSERT INTO plm_command VALUES (3, 1, 0, 'robokern', 'script', 0); 
