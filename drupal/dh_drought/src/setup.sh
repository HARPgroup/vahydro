# 
cd /tmp
wget http://water.weather.gov/precip/p_download_new/nws_precip_allpoint.tar.gz
tar -xvf nws_precip_allpoint.tar.gz  
shp2pgsql -s 4326 nws_precip_allpoint tmp_nwsgrid -D > tmp_nwsgrid.dump
cat tmp_nwsgrid.dump | psql -U postgres -h 192.168.0.21 -p 5432 drupal.dh03
# import the grid to tmp table
# insert features that do not exist
# insert hrapx and hrapy properties
# insert geometries that do NOT exist
# update geom on features that DO exist
# insert normal monthly values as dh_timeseries_weather where they do NOT exist


# go to psql
insert into dh_feature (hydrocode, name, bundle, ftype)
select a.hrapx || '-' || a.hrapy, 'NWS ' || hrapx || '-' || hrapy,  
  'weather_sensor', 'nws_precip'
from tmp_nwsgrid as a 
left outer join dh_feature as b 
on (
  (a.hrapx || '-' || a.hrapy) = b.hydrocode
)
left outer join 
( 
  select 'bayws', st_extent(dh_geofield_geom) as geom_extent  
  from dh_feature as a
  left outer join field_data_dh_geofield as b
  on (
    a.hydroid = b.entity_id
    and b.entity_type = 'dh_feature'
  )
  where a.bundle = 'watershed'
  and a.ftype = 'vahydro'
  and a.fstatus = 'active'
) as d 
on ( a.geom && d.geom_extent) 
where b.hydroid is null 
and a.geom && d.geom_extent
;


insert into field_data_dh_geofield ( 
  entity_type, bundle, deleted, entity_id, 
  revision_id, language, delta, dh_geofield_geom, 
  dh_geofield_geo_type, dh_geofield_lat, dh_geofield_lon, dh_geofield_left,
  dh_geofield_top, dh_geofield_right, dh_geofield_bottom, dh_geofield_geohash)
SELECT
  'dh_feature', 'weather_sensor', 0, b.hydroid, 
  b.hydroid, 'und', 0, a.geom, 
  'point', ST_y(a.geom), ST_x(a.geom), ST_x(a.geom), 
  ST_y(a.geom), ST_x(a.geom), ST_y(a.geom), ST_GeoHash(a.geom, 16) 
from tmp_nwsgrid as a 
left outer join dh_feature as b 
on (
  (a.hrapx || '-' || a.hrapy) = b.hydrocode
)
left outer join field_data_dh_geofield as c 
on (
  b.hydroid = c.entity_id
  and c.entity_type = 'dh_feature'
)
where b.hydroid is NOT null 
and c.entity_id is null 
;
