create temp view tmp_exempt_ranges as (
  select name, hydroid, ftype, pnp, ex_var, 
    round(max(exval)::numeric,4) as exval, 
    round(max(propvalue_mgd)::numeric,4) as max_propval, 
    round(min(propvalue_mgd)::numeric,4) as min_propval 
  from (
    select b.hydroid, b.name, v.varkey, a.propcode as ex_var,  a.propvalue as exval, b.ftype, 
      CASE 
        WHEN b.ftype like '%power%' THEN 'power' 
        ELSE 'non-power' 
      END as pnp,
      CASE 
        WHEN v.varkey = 'max_pre89_mgm' THEN c.propvalue / 31.0
        WHEN v.varkey = 'pre_89_mgm' THEN c.propvalue / 31.0
        WHEN v.varkey = 'max_pre89_mgy' THEN c.propvalue / 365.0
        WHEN v.varkey = 'wd_mgy_max_pre1990' THEN c.propvalue / 365.0
        WHEN v.varkey = 'rfi_wd_capacity_mgy' THEN c.propvalue / 365.0
        WHEN v.varkey = 'rfi_exempt_wd' THEN c.propvalue / 365.0
        ELSE c.propvalue
      END as propvalue_mgd
    from dh_properties as a 
    left outer join dh_feature as b 
    on (
      a.featureid = b.hydroid 
      and a.entity_type = 'dh_feature'
    ) 
    left outer join dh_properties as c 
    on (
      c.featureid = b.hydroid 
      and c.entity_type = 'dh_feature'
    ) 
    left outer join dh_variabledefinition as v 
    on (
      c.varid = v.hydroid 
      and v.vocabulary in ('safe_yield', 'water_exemption') 
      and v.varkey <> 'permit_exemption_code'
    )
    where a.propname = 'vwp_exempt_mgd' 
        and a.entity_type = 'dh_feature' 
        and b.bundle = 'intake'
        and c.propvalue > 0.0 
        and v.varkey is not null
  ) as foo
  group by name, hydroid, ex_var, ftype, pnp 
);

-- QA
select * from tmp_exempt_ranges 
where 
  ( 
    (max_propval > exval)
    or (min_propval > exval) 
  )
  and ex_var not like 'vwp%'
  and ex_var not like 'wsp%'
  and ex_var not like '401%'
;


select pnp, sum(exval) as exval, sum(max_propval) as max_val, sum(min_propval) as min_val
from tmp_exempt_ranges 
where ex_var not like 'vwp%'
  and ex_var not like 'wsp%'
  and ex_var not like '401%' 
group by pnp 
;
