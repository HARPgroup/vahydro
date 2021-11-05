#!/bin/sh

q="update field_data_dh_geofield set dh_geofield_geom = st_setsrid(dh_geofield_geom,4326)"
q="$q  where st_srid(dh_geofield_geom) <> 4326;"
echo $q | psql -U robertwb drupal.alpha
echo $q | psql -U robertwb drupal.beta
echo $q | psql -U robertwb drupal.dh03

q="update dh_feature set name = 'unknown' "
q="$q  where (name = '' or name is null) and bundle in ('waterbody', 'waterline')"
echo $q | psql -U robertwb drupal.alpha
echo $q | psql -U robertwb drupal.beta
echo $q | psql -U robertwb drupal.dh03
