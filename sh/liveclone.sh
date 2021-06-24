#!/bin/sh
host="localhost"
srcdb="drupal.dh03"
admin="robertwb"
if [ "$1" = '' ]; then
   echo "Usage: liveclone.sh dbname dbsource=$srcdb [port]"
   exit
else
   dbname=$1
fi

if [ "$2" = '' ]; then
   echo "Usage: liveclone.sh dbname dbsource=$srcdb [port]"
   exit
else
   srcdb=$2
fi

if [ "$3" = '' ]; then
  port=5432
else
   port=$3
fi


dropdb $dbname -U $admin -p $port -h $host
echo "cmd: CREATE DATABASE \"$dbname\" WITH TEMPLATE \"$srcdb\" OWNER $admin; | psql -U $admin -p $port -h $host"
echo "CREATE DATABASE \"$dbname\" WITH TEMPLATE \"$srcdb\" OWNER $admin; " | psql -U $admin -p $port -h $host
echo "cmd: ALTER DATABASE \"$dbname\" SET bytea_output = 'escape'; | psql $dbname -U $admin -p $port -h $host"
echo "ALTER DATABASE \"$dbname\" SET bytea_output = 'escape';" | psql $dbname -U $admin -p $port -h $host
echo "cmd: CREATE EXTENSION postgis; | psql $dbname -U $admin -p $port -h $host"
echo "CREATE EXTENSION postgis;" | psql $dbname -U $admin -p $port -h $host
echo "cmd: grant all on database \"$dbname\" to drupal | psql $dbname -U $admin -p $port -h $host"
echo "grant all on database \"$dbname\" to drupal" | psql $dbname -U $admin -p $port -h $host

