
COPY (
  select mp.hydroid as mp_id as featureid, 
    fac.hydroid as fac_id, 
    f_model.pid as f_model_pid , 
    mp_model.pid as mp_model_pid 
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
  where mp_model.pid is NOT null 
    and f_model.pid IS NOT NULL 
    and fac.bundle = 'facility'
    and mp.bundle = 'intake'
    and fac.fstatus <> 'duplicate'
    and mp.bundle <> 'duplicate'
) to '/tmp/mp_model_shell_links.txt' WITH DELIMITER E'\t';

