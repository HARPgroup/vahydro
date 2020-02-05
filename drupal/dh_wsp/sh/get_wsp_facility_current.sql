select 'wsp2020_2020_mgy' as propname, 
  'wsp_facility_mgy' as varkey,
  hydroid as featureid, 
  sum(fac_net_wd) as propvalue, 
  'dh_feature' as entity_type, 
  'wsp_current_use_mgy' as propcode 
from tmp_wsp_fac_net 
where hydroid in ($hydroids)
group by hydroid;