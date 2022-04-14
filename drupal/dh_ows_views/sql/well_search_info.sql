CREATE or REPLACE VIEW view_dh_ows_wellinfo as (
  select a.hydroid, 
    b.proptext_value as usgs_local,
    c.proptext_value as deq_wellno,
    d.proptext_value as vdh_hdin,
    e.proptext_value as vdh_pwsid 
  from dh_feature as a 
  left outer join dh_properties as bp 
  on (a.hydroid = bp.featureid
    and bp.propname = 'usgs_local'
  ) 
  left outer join dh_properties as cp 
  on (a.hydroid = cp.featureid
    and cp.propname = 'deq_wellno'
  ) 
  left outer join dh_properties as dp 
  on (a.hydroid = dp.featureid
    and dp.propname = 'vdh_hdin'
  ) 
  left outer join dh_properties as ep 
  on (a.hydroid = ep.featureid
    and ep.propname = 'vdh_pwsid'
  ) 
  left outer join field_data_proptext as b
  on (bp.pid = b.entity_id)
  left outer join field_data_proptext as c
  on (cp.pid = c.entity_id)
  left outer join field_data_proptext as d
  on (dp.pid = d.entity_id)
  left outer join field_data_proptext as e
  on (ep.pid = e.entity_id)
  where a.bundle = 'well' 
);