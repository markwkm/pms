my_user=robot
my_password=xxxxxx
my_host=bugs.brt.osdl.org
my_db=plm

pg_user=plm
pg_host=testdb
pg_db=plm_production

patch_path=root@storage:/var/plm/patch/

# Export mysqldb to .dat files
rm *.sql
./plm_dump.sh $my_user $my_host $my_db $my_password

# Convert to postgresql
./plm_import_to_pgsql.pl

# Import to postgres DB
psql --user="$pg_user" --host="$pg_host" --password $pg_db <plm_import_pgsql >run.out  2>run.err

# get the patch files to insert as eu 64 bit into the patches field (Comment out to not import patch files)
echo Enter the password to get the patch files:
scp -r $patch_path ./
./plm_import_patches.pl  $pg_db $pg_host $pg_user
