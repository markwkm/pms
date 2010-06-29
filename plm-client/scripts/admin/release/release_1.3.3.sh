#!/bin/bash

user=robot
pass=''
plm_db=plm
root_dir=/root

# These are the scripts for all the database changes.
cd ../sql || exit 1

if [ -z "$pass" ]; then
	echo "Enter admin password:"
	read pass
fi

# Run all these scripts.
mysql -u $user --password="$pass" $plm_db <./plm_cvs_setup.part3.sql
mysql -u $user --password="$pass" $plm_db <./database_cleanup.sql
mysql -u $user --password="$pass" $plm_db <./plm_build_comm.part1.sql
mysql -u $user --password="$pass" $plm_db <./reverse_patches.sql
mysql -u $user --password="$pass" $plm_db <./software_description.sql
mysql -u $user --password="$pass" $plm_db <./software_add/add_1.sysstat.sql
mysql -u $user --password="$pass" $plm_db <./software_add/add_2.postgressql.sql


