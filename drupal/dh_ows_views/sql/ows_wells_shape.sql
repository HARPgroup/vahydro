create or replace view view_dh_ows_wells as
select a.hydroid, a.hydrocode, a.name, a.ftype, 
  CASE 
    WHEN b.dh_landelev_value = -9999 THEN NULL 
    ELSE b.dh_landelev_value 
  END as land_elev, 
  d.itab, 
  c.dh_geofield_geom as the_geom 
from dh_feature as a 
left outer join field_data_dh_landelev as b 
  on (a.hydroid = b.entity_id) 
left outer join field_data_dh_geofield as c 
  on (a.hydroid = c.entity_id) 
left outer join (
  select a.wellid_target_id, 
    string_agg((b.ftype || ': ' || fromdepth::varchar || ' to ' || todepth::varchar), '\n<br>') as itab 
  from field_data_wellid as a 
  left outer join dh_boreholelog as b 
    on (a.entity_id = b.bhlid) 
  group by a.wellid_target_id 
) as d 
  on (
    a.hydroid = d.wellid_target_id
  ) 
where a.bundle = 'well' 
  and c.dh_geofield_geom is not null
;
