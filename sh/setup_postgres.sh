# run these functions after setup of database for query extensions
db_server_name="dbase1"
cat /opt/model/vahydro/sql/pg_functions.sql | psql -h $dbase_server_name drupal.dh03
