# In production and testdev
DROP TABLE plm_user_to_filter;
DROP TABLE plm_user_to_queue;
DROP TABLE plm_queue;
DROP TABLE plm_approval;
DROP TABLE plm_approval_state;

# In production
DROP TABLE plm_watch;
DROP TABLE plm_queue_to_watch;
DROP TABLE plm_user_to_watch;
DROP TABLE plm_patch_to_watch;
DROP TABLE plm_group_to_watch;
DROP TABLE plm_filter_to_watch;
DROP TABLE plm_auth;
DROP TABLE patch_tag;
DROP TABLE plm_patch_state;

# In production and testdev
ALTER TABLE plm_user DROP COLUMN plm_auth_id;

DELETE FROM plm_index WHERE token='plm_user_to_filter';
DELETE FROM plm_index WHERE token='plm_user_to_queue';
DELETE FROM plm_index WHERE token='plm_queue';
DELETE FROM plm_index WHERE token='plm_approval';
DELETE FROM plm_index WHERE token='plm_approval_state';

# In production only
DELETE FROM plm_index WHERE token='plm_watch';
DELETE FROM plm_index WHERE token='plm_user_to_watch';
DELETE FROM plm_index WHERE token='plm_queue_to_watch';
DELETE FROM plm_index WHERE token='plm_patch_to_watch';
DELETE FROM plm_index WHERE token='plm_group_to_watch';
DELETE FROM plm_index WHERE token='plm_filter_to_watch';
DELETE FROM plm_index WHERE token='plm_auth';
DELETE FROM plm_index WHERE token='plm_patch_state';
