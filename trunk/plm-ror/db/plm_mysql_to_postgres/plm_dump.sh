my_user=$1
my_host=$2
my_db=$3
my_password=$4

echo $my_user $my_host $my_db $my_password

#my_admin_db=USERDB

rm *.dat

print_data () {
    echo $2| mysql --batch --user="$my_user" --password="$my_password" --host=$my_host --database=$my_db >> $1.dat
}
#print_admin () {
#    echo $2| mysql --batch --user="$my_user" --password="$my_password" --host=$my_host --database=$my_admin_db >> $1.dat
#}

# plm_command
echo exporting plm_command
print_data commands "SELECT id, plm_command_set_id, command_order, command, command_type, expected_result FROM plm_command;"
# plm_command_set
echo exporting plm_command_set
print_data command_sets "SELECT id, name, command_set_type FROM plm_command_set;"
# plm_filter
echo exporting plm_filter
print_data filters "SELECT id, created, modified, plm_software_id, name, location, runtime, plm_filter_type_id, location FROM plm_filter;"
# plm_filter_request
echo exporting plm_filter_request
print_data filter_requests "SELECT plm_filter_id, plm_patch_id, priority, result, result_detail, output, created, modified, id, plm_filter_request_state_id FROM plm_filter_request;"
# plm_filter_request_state
echo exporting plm_filter_request_state
print_data filter_request_states "SELECT code, detail FROM plm_filter_request_state;"
# plm_filter_type
echo exporting plm_filter_type
print_data filter_types "SELECT id, created, modified, code, plm_software_id FROM plm_filter_type;"
# plm_group
# echo exporting plm_group?
# print_data plm_group "SELECT id, rsf, created, deleted, modified, accessed, plm_private_flag, name FROM plm_group;"
# plm_index
# echo exporting plm_index?
# print_data plm_index "SELECT token, lock_key, value FROM plm_index;"
# plm_keyword
# echo exporting plm_keyword?
# print_data plm_keyword "SELECT id, rsf, created, deleted, accessed, name FROM plm_keyword;"
# plm_note
# echo exporting plm_note?
# print_data plm_note "SELECT id, rsf, created, deleted, accessed, plm_user_id, plm_patch_id, plm_note_type_id, subject, content FROM plm_note;"
# plm_note_type
# echo exporting plm_note_type?
# print_data plm_note_type "SELECT id, rsf, deleted, created, accessed, name FROM plm_note_type;"
# plm_patch
echo exporting plm_patch
print_data patches "SELECT id, created, modified, plm_software_id, md5sum, plm_applies_id, name, plm_user_id, plm_source_id, reverse, remote_identifier, patch_path FROM plm_patch;"
# plm_patch_acl
echo exporting plm_patch_acl
print_data patch_acls "SELECT id, plm_software_id, name, reason, regex FROM plm_patch_acl;"
# plm_patch_acl_to_user
echo exporting plm_patch_acl_to_user
print_data patch_acls_users "SELECT plm_patch_acl_id, plm_user_id FROM plm_patch_acl_to_user;"
# plm_patch_to_keyword
# echo exporting plm_patch_to_keyword?
# print_data plm_patch_to_keyword "SELECT id, plm_keyword_id, plm_patch_id FROM plm_patch_to_keyword;"
# plm_software
echo exporting plm_software
print_data softwares "SELECT id, created, deleted, name, description FROM plm_software;"
# plm_software_to_command_set
echo exporting plm_software_to_command_set
print_data command_sets_softwares "SELECT plm_software_id, plm_command_set_id, min_plm_patch_id, max_plm_patch_id FROM plm_software_to_command_set;"
# plm_source
echo exporting plm_source
print_data sources "SELECT id, created, deleted, plm_software_id, root_location, plm_source_type FROM plm_source;"
# plm_source_sync
echo exporting plm_source_sync
print_data sources_syncs "SELECT id, created, modified, plm_source_id, search_location, depth, wanted_regex, not_wanted_regex, baseline, applies_regex, name_substitution, descriptor, last_timestamp FROM plm_source_sync;"
# plm_user
echo exporting plm_user
print_data users "SELECT id, created, modified, name, email, pass, admin_flag FROM plm_user;"
# plm_user_to_group
# echo exporting plm_user_to_group?
# print_data plm_user_to_group "SELECT id, created, plm_user_id, plm_group_id, rev_flag FROM plm_user_to_group;"

# Sequences
declare -a tables_seqs
tables_seqs=(
commands_id_seq
command_sets_id_seq
filters_id_seq
filter_requests_id_seq
filter_types_id_seq
patches_id_seq
patch_acls_id_seq
softwares_id_seq
sources_id_seq
sources_syncs_id_seq
users_id_seq
)

declare -a tables_with_seqs
tables_with_seqs=(
plm_command
plm_command_set
plm_filter
plm_filter_request
plm_filter_type
plm_patch
plm_patch_acl
plm_software
plm_source
plm_source_sync
plm_user
)

element_count=${#tables_with_seqs[@]}
index=0
while [ "$index" -lt "$element_count" ]
do
    seq_val=`echo "SELECT MAX(id) '' FROM ${tables_with_seqs[$index]}"| mysql --batch --user="$my_user" --password="$my_password" --host=$my_host --database=$my_db`
    let "seq_val = $seq_val + 1"
    echo ALTER SEQUENCE ${tables_seqs[$index]} RESTART $seq_val';' >> z_sequences.sql
    let "index = $index + 1"
done
