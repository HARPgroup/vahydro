-- Create Use Fractions for Virtual MPs on Virtual Facilities at county level
-- for water supply plan/current withdrawal/total-permitted and/or other county level analyses.

create temporary view vahydro_mp_current_active as (
  select hydroid, mplink.dh_link_facility_mps_target_id as fac_hydroid,
  dh_feature.bundle, fstatus, 
  -- use max just in case there are dupes 
  max(propvalue) as wd_current_mgy
  from dh_feature 
  left outer join field_data_dh_link_facility_mps as mplink
  on (
    mplink.entity_id = hydroid 
  )
  left outer join dh_properties 
  on (
    hydroid = featureid 
    and dh_properties.entity_type = 'dh_feature' 
    and propname = 'wd_current_mgy'
  )
  where dh_feature.bundle in ('intake', 'well') 
  and propvalue is not null 
  and fstatus <> 'duplicate'
  group by hydroid, dh_feature.bundle, fstatus, mplink.dh_link_facility_mps_target_id
);
  

-- County reported fractions SW/GW
create temporary table tmp_wsp_virtual_fracs as (
  select fips.hydrocode, virtual_facs.hydroid, round(sum(wells.wd_current_mgy)) as gw_current_mgy, 
    round(sum(intakes.wd_current_mgy)) as sw_current_mgy, 
    round(sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy)) as total_mgy,
    count(wells.*) as num_wells, count(intakes.*) as num_intakes,
    CASE 
      WHEN virtual_facs.ftype = 'wsp_plan_system-ssusm' THEN 0.0 
      WHEN sum(intakes.wd_current_mgy) > 0 AND sum(wells.wd_current_mgy) IS NULL THEN 1.0
      WHEN ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) > 0 
        THEN 
        sum(intakes.wd_current_mgy) / ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) 
      WHEN sum(intakes.wd_current_mgy) IS NULL  AND sum(wells.wd_current_mgy) IS NULL THEN 0.5
      ELSE 0.0
    END as sw_frac,
    CASE 
      -- always 
      WHEN virtual_facs.ftype = 'wsp_plan_system-ssusm' THEN 1.0 
      WHEN sum(wells.wd_current_mgy) > 0 AND sum(intakes.wd_current_mgy) IS NULL THEN 1.0
      WHEN ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) > 0 
        THEN 
        sum(wells.wd_current_mgy) / ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) 
      WHEN sum(intakes.wd_current_mgy) IS NULL AND sum(wells.wd_current_mgy) IS NULL THEN 0.5
      ELSE 0.0
    END as gw_frac 
  from dh_feature as virtual_facs
  left outer join dh_feature as fips 
  on (
    virtual_facs.hydrocode like ('%_' || fips.hydrocode)
    and fips.bundle in ('usafips', 'tiger_place')
  )
  left outer join field_data_dh_link_admin_fa_usafips as lnk 
  on (
    fips.hydroid = lnk.dh_link_admin_fa_usafips_target_id
  )
  left outer join dh_feature as fac 
  on (
    lnk.entity_id = fac.hydroid 
    and fac.ftype not ilike '%power%'
  )
  left outer join (
    select fac_hydroid, sum(wd_current_mgy ) as wd_current_mgy
    from vahydro_mp_current_active 
    where bundle = 'well'
    and fstatus = 'active' 
    group by fac_hydroid
  ) as wells
  on (
    fac.hydroid = wells.fac_hydroid 
  )
  left outer join (
    select fac_hydroid, sum(wd_current_mgy ) as wd_current_mgy
    from vahydro_mp_current_active 
    where bundle = 'intake'
    and fstatus = 'active' 
    group by fac_hydroid
  ) as intakes
  on (
    fac.hydroid = intakes.fac_hydroid
  )
  where virtual_facs.ftype like 'wsp_plan_system%' 
  group by fips.hydrocode, virtual_facs.hydroid
  order by fips.hydrocode
);


-- County reported fractions SW/GW
-- we use all MPs here, not just active ones since that is what the totals are based on.
-- also, "active" is vague.
create temporary table tmp_facility_fracs as (
  select fac.hydroid, 
    CASE 
      WHEN sum(wells.wd_current_mgy) IS NULL THEN 0.0 
      ELSE round(sum(wells.wd_current_mgy)) 
    END as gw_current_mgy, 
    CASE 
      WHEN sum(intakes.wd_current_mgy) IS NULL THEN 0.0 
      ELSE round(sum(intakes.wd_current_mgy))
    END as sw_current_mgy, 
    round(sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy)) as total_mgy,
    wells.num_wells, intakes.num_intakes,
    CASE 
      WHEN sum(intakes.wd_current_mgy) > 0 AND sum(wells.wd_current_mgy) IS NULL THEN 1.0
      WHEN ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) > 0 
        THEN 
        sum(intakes.wd_current_mgy) / ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) 
      WHEN sum(intakes.wd_current_mgy) IS NULL  AND sum(wells.wd_current_mgy) IS NULL THEN 0.5
      ELSE 0.0
    END as sw_frac,
    CASE 
      -- always 
      WHEN sum(wells.wd_current_mgy) > 0 AND sum(intakes.wd_current_mgy) IS NULL THEN 1.0
      WHEN ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) > 0 
        THEN 
        sum(wells.wd_current_mgy) / ( sum(wells.wd_current_mgy) + sum(intakes.wd_current_mgy) ) 
      WHEN sum(intakes.wd_current_mgy) IS NULL AND sum(wells.wd_current_mgy) IS NULL THEN 0.5
      ELSE 0.0
    END as gw_frac 
  from dh_feature as fac 
  left outer join (
    select fac_hydroid, count(*) as num_wells, sum(wd_current_mgy ) as wd_current_mgy
    from vahydro_mp_current_active 
    where bundle = 'well'
    group by fac_hydroid
  ) as wells
  on (
    fac.hydroid = wells.fac_hydroid 
  )
  left outer join (
    select fac_hydroid, count(*) as num_intakes, sum(wd_current_mgy ) as wd_current_mgy
    from vahydro_mp_current_active 
    where bundle = 'intake'
    group by fac_hydroid
  ) as intakes
  on (
    fac.hydroid = intakes.fac_hydroid
  )
  where fac.bundle <> 'duplicate'
  and fac.ftype not like 'gw2%'
  and (intakes.fac_hydroid is not null or wells.fac_hydroid is not null)
  group by fac.hydroid, wells.num_wells, intakes.num_intakes
);

-- County Virtual Well and Intakes 
select 'dh_feature' as entity_type, vmp.hydroid as featureid, 
  'facility_use_fraction' as varkey, 
  'facility_use_fraction' as propname,
  CASE 
    WHEN vmp.bundle = 'intake' THEN vfac.sw_frac 
    WHEN vmp.bundle = 'well' THEN vfac.gw_frac 
    ELSE 0.0
  END as propvalue
from tmp_wsp_virtual_fracs as vfac 
left outer join field_data_dh_link_facility_mps as mplink
on (
  mplink.dh_link_facility_mps_target_id = vfac.hydroid 
)
left outer join dh_feature as vmp  
on (
  mplink.entity_id = vmp.hydroid 
)
;
