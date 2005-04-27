#  Thes are change to clean-up database and merge tables plm_patch and plm_software_version
#
#  Change data types in 'plm_archive'
#
ALTER TABLE plm_archive MODIFY COLUMN wanted_regex VARCHAR(255);
ALTER TABLE plm_archive MODIFY COLUMN not_wanted_regex VARCHAR(255);
ALTER TABLE plm_archive MODIFY COLUMN applies_regex VARCHAR(255);
ALTER TABLE plm_archive CHANGE COLUMN name_sub name_substitution VARCHAR(255);
ALTER TABLE plm_archive CHANGE COLUMN directory search_location VARCHAR(255);
ALTER TABLE plm_patch DROP COLUMN plm_patch_state_id;



#  Merge plm_patch and plm_software_version
#
#  First, export these tables as a backup!!
#
ALTER TABLE plm_patch ADD COLUMN patch_path VARCHAR(255);
ALTER TABLE plm_patch ADD COLUMN remote_identifier VARCHAR(255);

# This creates the script to update table plm_patch
SELECT CONCAT('UPDATE plm_patch SET patch_path=''', sv.location, '''\,remote_identifier=''', sv.filename, ''' WHERE name=''', p.name, '''\;') INTO OUTFILE '/tmp/update_plm_patch.out' FROM plm_patch p , plm_software_version sv WHERE p.name=sv.name;

# Now run the script /tmp/update_plm_patch.out.
source /tmp/update_plm_patch.out

#DROP TABLE plm_software_version;

DELETE FROM plm_index WHERE token = 'plm_software_version';
