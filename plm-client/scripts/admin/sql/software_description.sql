ALTER TABLE plm_software ADD COLUMN description VARCHAR(255);
UPDATE  plm_software  set description = 'Linux kernel source code, available from http://www.kernel.org.' where name = 'linux';
Alter TABLE plm_software MODIFY COLUMN description VARCHAR(255) NOT NULL;
