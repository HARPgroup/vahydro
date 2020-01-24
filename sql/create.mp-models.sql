
COPY (
  select mp.hydroid as featureid, 
    'dh_feature' as entity_type, 
    'om_model_element' as varkey, 
    replace(mp.name, '# Note: This reservior was off for the 2018 year due to needed dredging and repairs', '') as propname
  from dh_feature as mp 
  left outer join field_data_dh_link_facility_mps as mplink
  on (
    mplink.entity_id = mp.hydroid 
  )
  left outer join dh_feature as fac 
  on (
    mplink.dh_link_facility_mps_target_id = fac.hydroid
  )
  left outer join dh_properties as f_model 
  on (
    fac.hydroid = f_model.featureid 
    and f_model.entity_type = 'dh_feature' 
    and f_model.propcode = 'vahydro-1.0'
  )
  left outer join dh_properties as mp_model 
  on (
    mp.hydroid = mp_model.featureid 
    and mp_model.entity_type = 'dh_feature' 
    and mp_model.propcode = 'vahydro-1.0'
  )
  where mp_model.pid is null 
    and f_model.pid IS NOT NULL 
    and fac.bundle = 'facility'
    and mp.bundle = 'intake'
    and fac.fstatus <> 'duplicate'
    and mp.bundle <> 'duplicate'
) to '/tmp/mp_model_shells.txt' WITH DELIMITER E'\t';

