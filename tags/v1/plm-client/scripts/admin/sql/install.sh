my_user=mysql
my_password=mysql
my_host=localhost
my_db=plmexp

# Create database
echo "create database $my_db" | mysql -u $my_user --password=$my_password


# create tables
mysql --user="$my_user" --password="$my_password" --host=$my_host --database=$my_db < ./plm_setup_db.sql

