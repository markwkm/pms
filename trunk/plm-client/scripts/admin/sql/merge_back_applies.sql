ALTER TABLE plm_patch ADD COLUMN plm_applies_id INT NULL DEFAULT NULL;

SELECT CONCAT( 'UPDATE plm_patch SET plm_applies_id = ', target_plm_patch_id, ' WHERE id = ', plm_patch_id, '\;') INTO OUTFILE '/tmp/update_applies.sql' FROM plm_applies;

source /tmp/update_applies.sql

# We can drop tables plm_applies, plm_obsoletes.
