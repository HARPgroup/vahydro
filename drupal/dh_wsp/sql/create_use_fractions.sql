select 'dh_feature' as entity_type, mp.hydroid as featureid,
  'facility_use_fraction' as varkey, 'facility_use_fraction' as propname,
  CASE 
    WHEN facvar.propvalue > 0.0 THEN mpvar.propvalue / facvar.propvalue
    WHEN mpvar.propvalue is NULL then 0.0 
    ELSE 0.0
  END as propvalue 
from dh_feature as mp 
left outer join field_data_dh_link_facility_mps as link
on (
  link.entity_id = mp.hydroid
)
left outer join dh_feature as fac
on (
  link.dh_link_facility_mps_target_id = fac.hydroid
)
left outer join dh_properties as mpvar
on (
  mpvar.entity_type = 'dh_feature'
  and mpvar.featureid = mp.hydroid
  and mpvar.propname = 'wd_current_mgy'
)
left outer join dh_properties as facvar
on (
  facvar.entity_type = 'dh_feature'
  and facvar.featureid = fac.hydroid
  and facvar.propname = 'wd_current_mgy'
)
where mp.bundle in ('intake', 'well')
and fac.hydroid is not null
and facvar.propvalue is not null;