\set thisyear 2024
copy (
  select gage_name as name, 
  gage_hydrocode as hydrocode, 
  gage_hydroid as hydroid, 
  'drought_status_mllr' as varkey, 
  'drought_status_mllr' as propname, 
  thisyear, mllr_prob_pct10 as tsvalue
  from (
    select gage_feat.hydroid as gage_hydroid, gage_feat.hydrocode as gage_hydrocode,
     gage_feat.name as gage_name, extract(year from to_timestamp(gage_mllr_pct10.tstime)) as thisyear , 
     max(gage_mllr_pct10.tsvalue) as mllr_prob_pct10
    from dh_feature as gage_feat 
    left outer join dh_variabledefinition as geo_var 
    on (
      geo_var.varkey = 'auxiliary_geom'
    )
    left outer join dh_properties as gage_geo_prop
    on (
      gage_feat.hydroid = gage_geo_prop.featureid
      and gage_geo_prop.entity_type = 'dh_feature'
      and gage_geo_prop.varid = geo_var.hydroid
    )
    left outer join field_data_dh_geofield as gage_geo
    on (
      gage_geo.entity_id = gage_geo_prop.pid 
      and gage_geo.entity_type = 'dh_properties' 
    )
    left outer join dh_variabledefinition as mllr_var 
    on (
      mllr_var.vocabulary = 'drought' 
      and mllr_var.varkey like 'mllr%_%_10' 
    )
    left outer join dh_timeseries as gage_mllr_pct10
    on (
      gage_feat.hydroid = gage_mllr_pct10.featureid
      and gage_mllr_pct10.entity_type = 'dh_feature'
      and gage_mllr_pct10.varid = mllr_var.hydroid
    )
    where gage_feat.bundle = 'usgsgage'
      and extract(year from to_timestamp(gage_mllr_pct10.tstime)) = :thisyear 
    group by gage_feat.hydroid , gage_feat.hydrocode,
     gage_feat.name, extract(year from to_timestamp(gage_mllr_pct10.tstime))
  ) as foo 
  order by mllr_prob_pct10 DESC
) to '/tmp/mllr-export.txt' WITH HEADER CSV DELIMITER E'\t'
;



copy (
  select gage_name as name, gage_hydrocode as hydrocode, gage_hydroid as hydroid, 'drought_status_mllr' as varkey, thisyear, mllr_prob_pct10 as tsvalue
  from (
    select gage_feat.hydroid as gage_hydroid, 
      gage_feat.hydrocode as gage_hydrocode,
      gage_feat.name as gage_name, extract(year from to_timestamp(gage_mllr_pct10.tstime)) as thisyear , 
      max(gage_mllr_pct10.tsvalue) as mllr_prob_pct10
    from dh_feature as gage_feat 
    left outer join dh_variabledefinition as geo_var 
    on (
      geo_var.varkey = 'auxiliary_geom'
    )
    left outer join dh_properties as gage_geo_prop
    on (
      gage_feat.hydroid = gage_geo_prop.featureid
      and gage_geo_prop.entity_type = 'dh_feature'
      and gage_geo_prop.varid = geo_var.hydroid
    )
    left outer join field_data_dh_geofield as gage_geo
    on (
      gage_geo.entity_id = gage_geo_prop.pid 
      and gage_geo.entity_type = 'dh_properties' 
    )
    left outer join dh_variabledefinition as mllr_var 
    on (
      mllr_var.vocabulary = 'drought' 
      and mllr_var.varkey like 'mllr%_%_10' 
    )
    left outer join dh_timeseries as gage_mllr_pct10
    on (
      gage_feat.hydroid = gage_mllr_pct10.featureid
      and gage_mllr_pct10.entity_type = 'dh_feature'
      and gage_mllr_pct10.varid = mllr_var.hydroid
    )
    left outer join field_data_dh_link_facility_mps as link_wshed 
    on (
      gage_feat.hydroid = link_wshed.entity_id 
    )
    left outer join dh_feature as wshed 
    on (
      wshed.hydroid =  link_wshed.entity_id 
    )
    where gage_feat.bundle = 'usgsgage'
      and extract(year from to_timestamp(gage_mllr_pct10.tstime)) = :thisyear 
    group by gage_feat.hydroid , gage_feat.hydrocode,
     gage_feat.name, extract(year from to_timestamp(gage_mllr_pct10.tstime))
  ) as foo 
  order by mllr_prob_pct10 DESC
) to '/tmp/mllr-export.txt' WITH HEADER CSV DELIMITER E'\t'
;
