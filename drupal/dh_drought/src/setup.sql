# import the grid to tmp table
# insert features that do not exist
# insert hrapx and hrapy properties
# insert geometries that do NOT exist
# update geom on features that DO exist
# insert normal monthly values as dh_timeseries_weather where they do NOT exist

insert into dh_feature (hydrocode, name, bundle, ftype)
select a.hrapx || '-' || a.hrapy, 'NWS ' || hrapx || '-' || hrapy,  
  'weather_sensor', 'nws_precip'
from tmp_noaagrid as a 
left outer join dh_feature as b 
on (
  (a.hrapx || '-' || a.hrapy) = b.hydrocode
)
left outer join field_data_dh_geofield as c 
on ( 
  st_setsrid(c.dh_geofield_geom,4326) && 
  c.bundle = 'watershed'
  c.entity_type = 'dh_feature'
)
left outer join dh_feature as d 
on (
  c.entity_id = b.hydroid
)
where b.hydroid is null 
  and d.ftype = nhd_huc6
  and d.fstatus = 'active'
;
