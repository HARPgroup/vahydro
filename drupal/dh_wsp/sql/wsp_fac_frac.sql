create temp view tmp_fac_current as (
  select fac.hydroid, 
    -- fac.name, 
    fac.fstatus,
    max(fac_wd.propvalue) as fac_current_mgy
  from dh_feature as fac 
  left outer join dh_properties as fac_wd 
  on (
    fac_wd.featureid = fac.hydroid
    and fac_wd.entity_type = 'dh_feature'
    and fac_wd.propname = 'wd_current_mgy'
  )
  where fac.bundle = 'facility'
    and fac.fstatus <> 'duplicate' 
    and fac.ftype not ilike 'gw2%'
  group by fac.hydroid, fac.name, fac.fstatus
);

create temp view tmp_wsp_sys_fac_part as (
  -- aggregate wd_current_mgy from multi-facility systems
  select wsp.adminid, fac.hydroid, wsp.name, fac.ftype,
    CASE 
      WHEN max(fac_wd.propvalue) IS NOT NULL THEN max(fac_wd.propvalue)
      ELSE 0.0 
    END as sys_fac_part 
  from dh_adminreg_feature as wsp
  left outer join field_data_dh_link_feature_submittal as lnk
  on (
    wsp.adminid = lnk.entity_id 
  )
  left outer join dh_feature as fac
  on (
    lnk.dh_link_feature_submittal_target_id = fac.hydroid
  ) 
  left outer join dh_properties as fac_wd
  on (
    fac_wd.featureid = fac.hydroid
    and fac_wd.entity_type  = 'dh_feature'
    and fac_wd.propname = 'wd_current_mgy'
  )
  WHERE wsp.ftype like 'wsp_plan_system-%' 
  and fac.fstatus not in ( 'duplicate', 'inactive') 
  and fac.ftype not ilike 'gw2%'
  group by wsp.adminid, fac.hydroid, wsp.name
);

create or replace temp view tmp_wsp_sys_demands as (
  select wsp.adminid, max(sys_wd.propvalue) as sys_wd
  from dh_adminreg_feature as wsp
  left outer join dh_variabledefinition as var
  on (
    varkey = 'wsp_current_use_mgy'
  )
  left outer join dh_properties as sys_wd 
  on (
    sys_wd.featureid = wsp.adminid
    and sys_wd.entity_type = 'dh_adminreg_feature'
    and sys_wd.varid = var.hydroid
  )
  where wsp.ftype like 'wsp_plan_system-%' 
  group by wsp.adminid 
);

create or replace temp view tmp_wsp_sys_future_demands as (
  select wsp.adminid, max(sys_wd.propvalue) as sys_wd
  from dh_adminreg_feature as wsp
  left outer join dh_variabledefinition as var
  on (
    varkey = 'wsp_wd_future_mgy' 
  )
  left outer join dh_properties as sys_wd 
  on (
    sys_wd.featureid = wsp.adminid
    and sys_wd.entity_type = 'dh_adminreg_feature'
    and sys_wd.varid = var.hydroid
  )
  where wsp.ftype like 'wsp_plan_system-%' 
  group by wsp.adminid 
);


create temp view tmp_wsp_sys_sum_multifac as (
  -- aggregate wd_current_mgy from multi-facility systems
  select wsp.adminid, wsp.name, max(sys_wd.propvalue) as sys_wd,
    CASE 
      WHEN sum(fac_wd.propvalue) IS NOT NULL THEN sum(fac_wd.propvalue) 
      ELSE 0.0 
    END as sys_fac_sum,
    count(fac.hydroid) as num_facs
  from dh_adminreg_feature as wsp
  left outer join field_data_dh_link_feature_submittal as lnk
  on (
    wsp.adminid = lnk.entity_id 
  )
  left outer join dh_feature as fac
  on (
    lnk.dh_link_feature_submittal_target_id = fac.hydroid
  ) 
  left outer join dh_properties as fac_wd
  on (
    fac_wd.featureid = fac.hydroid
    and fac_wd.entity_type  = 'dh_feature'
    and fac_wd.propname = 'wd_current_mgy'
  )
  left outer join dh_properties as sys_wd 
  on (
    sys_wd.featureid = wsp.adminid
    and sys_wd.entity_type = 'dh_adminreg_feature'
    and sys_wd.propname = 'wsp_current_use_mgy'
  )
  WHERE wsp.ftype like 'wsp_plan_system-%' 
  and fac.fstatus not in ( 'duplicate', 'inactive')
  group by wsp.adminid, wsp.name
);

-- all systems purchased water totals 
create or replace temp view tmp_wsp_sys_pw as (
  select adminid, 
    CASE WHEN sum(sys_pw_mgd.propvalue) IS NULL THEN 0.0
    ELSE sum(sys_pw_mgd.propvalue)
  END as sys_pw_mgd 
  from dh_adminreg_feature as wsp 
  left outer join field_data_field_dha_link_modification as src_link
  on (
    field_dha_link_modification_target_id = wsp.adminid 
  )
  left outer join dh_properties as src_type 
  on (
    src_type.featureid = src_link.entity_id 
    and src_type.propname = 'wsp_wd_src_type' 
    and src_type.propcode = 'pw' 
  )
  left outer join dh_properties as sys_pw_mgd 
  on (
    sys_pw_mgd.featureid = src_link.entity_id
    and sys_pw_mgd.entity_type = 'dh_adminreg_feature'
    and sys_pw_mgd.propname = 'wsp_pw_wd_current_mgd'
    and sys_pw_mgd.propvalue > 0 
  )
  WHERE wsp.ftype like 'wsp_plan_system-%' 
  group by adminid 
);

create or replace temp view tmp_sys_pw_frac as (
  select bar.adminid,
    CASE 
      WHEN bar.sys_wd > 0 AND (buzz.sys_pw_mgd * 365.25) > bar.sys_wd THEN 1.0
      WHEN bar.sys_wd > 0 THEN (buzz.sys_pw_mgd * 365.25) / bar.sys_wd
      ELSE 0.0 
    END as sys_pw_frac
  from tmp_wsp_sys_demands as bar 
  left outer join tmp_wsp_sys_pw as buzz 
  on (
    bar.adminid = buzz.adminid
  )
);
  
create or replace temp view tmp_wsp_fac_net as (
  select foo.*, bar.sys_wd, bar.sys_future_wd, 
    round(bar.sys_fac_frac::numeric,6) as sys_fac_frac, 
    round(bar.sys_pw_frac::numeric,6) sys_pw_frac, 
    bar.num_facs,
    round( (bar.sys_fac_frac * bar.sys_wd)::numeric,4) as fac_total,
    round( (bar.sys_fac_frac * (1.0 - bar.sys_pw_frac) * bar.sys_wd)::numeric,4) as fac_net_wd,
    round( (bar.sys_fac_frac * (1.0 - bar.sys_pw_frac) * bar.sys_future_wd)::numeric,4) as fac_net_future_wd
  from tmp_fac_current as foo 
  left outer join (
    select bar.adminid, bar.sys_fac_sum, baz.sys_fac_part, baz.hydroid, bar.num_facs,
      CASE 
        WHEN baz.ftype ilike 'wsp_plan_system-%' THEN 1.0
        WHEN bar.num_facs = 1 THEN 1.0
        WHEN bar.sys_fac_sum = 0 THEN 0.0
        WHEN bar.sys_fac_sum IS NULL THEN 0.0
        WHEN baz.sys_fac_part IS NULL THEN 0.0 
        ELSE baz.sys_fac_part / bar.sys_fac_sum
      END as sys_fac_frac, bar.sys_wd, bozo.sys_wd as sys_future_wd, 
      buzz.sys_pw_frac
    from tmp_wsp_sys_fac_part as baz 
    left outer join tmp_wsp_sys_sum_multifac as bar 
    on (
      baz.adminid = bar.adminid
    )
    left outer join tmp_sys_pw_frac as buzz 
    on (
      buzz.adminid = bar.adminid 
    )
    left outer join tmp_wsp_sys_future_demands as bozo 
    on (
      bozo.adminid = bar.adminid 
    )
  ) as bar 
  on (
    foo.hydroid = bar.hydroid 
  )
);
create temp table tmp_current_mgy_updated as (
  select fac.hydroid, 
    fac.ftype,
    model.propname, 
    max(fac_wd.propvalue) as fac_current_mgy,
    sum(mp_wd.propvalue) as current_mgy,
    array_accum(mp.hydroid) as mp_list,
    rseg.hydrocode as rseg_hydrocode,
    substr(rseg.hydrocode, 17) as riverseg,
    model_rseg.propcode as model_rseg,
    model.pid as model_pid
  from dh_feature as fac 
  left outer join field_data_dh_link_facility_mps as lnk
  on (
    lnk.entity_type = 'dh_feature'
    and lnk.dh_link_facility_mps_target_id = fac.hydroid
  )
  left outer join dh_feature as mp 
  on (mp.hydroid = lnk.entity_id)
  left outer join field_data_dh_geofield as mpg 
  on (
    mpg.entity_type = 'dh_feature'
    and mpg.entity_id = mp.hydroid
  )
  left outer join field_data_dh_geofield as rg
  on (
    rg.entity_type = 'dh_feature'
    and rg.bundle = 'watershed'
    and st_contains(
      st_setsrid(rg.dh_geofield_geom,4326), st_setsrid(mpg.dh_geofield_geom,4326) 
    )
  ) 
  left outer join dh_feature as rseg 
  on (rseg.hydroid = rg.entity_id)
  -- now get the data 
  left outer join dh_properties as fac_wd 
  on (
    fac_wd.entity_type = 'dh_feature'
    and fac_wd.featureid = fac.hydroid
    and fac_wd.propname = 'wd_current_mgy'
  )
  left outer join dh_properties as mp_wd 
  on (
    mp_wd.entity_type = 'dh_feature'
    and mp_wd.featureid = mp.hydroid
    and mp_wd.propname = 'wd_current_mgy'
  )
  -- now the model
  left outer join dh_properties as model 
  on (
    model.entity_type = 'dh_feature'
    and model.featureid = fac.hydroid
    and model.propcode = 'vahydro-1.0'
  )
  left outer join dh_properties as model_rseg
  on (
    model_rseg.entity_type = 'dh_properties'
    and model_rseg.featureid = model.pid
    and model_rseg.propname = 'riverseg'
  )
  where rseg.hydroid is not null
    and rseg.ftype = 'vahydro'
  -- this must be here or we won't get valid results
  and model_rseg.propcode = substr(rseg.hydrocode, 17) 
  -- limit to a single facility for testing
  --  and fac.hydroid = 71956 
    and mp.bundle = 'intake'
  group by rseg.hydrocode,
    substr(rseg.hydrocode, 17), model.pid, fac.hydroid, model_rseg.propcode, model.propname, fac.ftype
);


create or replace temp view tmp_current_mgy_gw as (
  select fac.hydroid, 
    fac.ftype,
    model.propname, 
    max(fac_wd.propvalue) as fac_current_mgy,
    sum(mp_wd.propvalue) as current_mgy,
    array_accum(mp.hydroid) as mp_list,
    rseg.hydrocode as rseg_hydrocode,
    substr(rseg.hydrocode, 17) as riverseg,
    model_rseg.propcode as model_rseg,
    model.pid as model_pid
  from dh_feature as fac 
  left outer join field_data_dh_link_facility_mps as lnk
  on (
    lnk.entity_type = 'dh_feature'
    and lnk.dh_link_facility_mps_target_id = fac.hydroid
  )
  left outer join dh_feature as mp 
  on (mp.hydroid = lnk.entity_id)
  left outer join field_data_dh_geofield as mpg 
  on (
    mpg.entity_type = 'dh_feature'
    and mpg.entity_id = mp.hydroid
  )
  left outer join field_data_dh_geofield as rg
  on (
    rg.entity_type = 'dh_feature'
    and rg.bundle = 'watershed'
    and st_contains(
      st_setsrid(rg.dh_geofield_geom,4326), st_setsrid(mpg.dh_geofield_geom,4326) 
    )
  ) 
  left outer join dh_feature as rseg 
  on (rseg.hydroid = rg.entity_id)
  -- now get the data 
  left outer join dh_properties as fac_wd 
  on (
    fac_wd.entity_type = 'dh_feature'
    and fac_wd.featureid = fac.hydroid
    and fac_wd.propname = 'wd_current_mgy'
  )
  left outer join dh_properties as mp_wd 
  on (
    mp_wd.entity_type = 'dh_feature'
    and mp_wd.featureid = mp.hydroid
    and mp_wd.propname = 'wd_current_mgy'
  )
  -- now the model
  left outer join dh_properties as model 
  on (
    model.entity_type = 'dh_feature'
    and model.featureid = fac.hydroid
    and model.propcode = 'vahydro-1.0'
  )
  left outer join dh_properties as model_rseg
  on (
    model_rseg.entity_type = 'dh_properties'
    and model_rseg.featureid = model.pid
    and model_rseg.propname = 'riverseg'
  )
  where rseg.hydroid is not null
    and rseg.ftype = 'vahydro'
  -- this must be here or we won't get valid results
  and model_rseg.propcode = substr(rseg.hydrocode, 17) 
  -- limit to a single facility for testing
  --  and fac.hydroid = 71956 
    and mp.bundle = 'well'
    and mp.ftype NOT LIKE 'gw2%'
  group by rseg.hydrocode,
    substr(rseg.hydrocode, 17), model.pid, fac.hydroid, model_rseg.propcode, model.propname, fac.ftype
);



