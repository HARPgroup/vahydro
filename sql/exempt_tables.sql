
create or replace view tmp_mp_riverseg as (  select fac.hydroid as fac_hydroid, mp.hydroid as hydroid,    fac.ftype, mp.name,    max(substr(rseg.hydrocode, 17)) as riverseg,    CASE      WHEN max(rseg.hydrocode) like 'vahydrosw_wshed_O%' THEN 'non-tidal'      WHEN max(rseg.hydrocode) like 'vahydrosw_wshed_B%' THEN 'non-tidal'      WHEN max(rseg.hydrocode) like 'vahydrosw_wshed_T%' THEN 'non-tidal'      WHEN max(rseg.hydrocode) like '%0000%' THEN 'tidal'      ELSE 'non-tidal'    END as tnt  from dh_feature as fac   left outer join field_data_dh_link_facility_mps as lnk  on (    lnk.entity_type = 'dh_feature'    and lnk.dh_link_facility_mps_target_id = fac.hydroid  )  left outer join dh_feature as mp   on (mp.hydroid = lnk.entity_id)  left outer join field_data_dh_geofield as mpg   on (    mpg.entity_type = 'dh_feature'    and mpg.entity_id = mp.hydroid  )  left outer join field_data_dh_geofield as rg  on (    rg.entity_type = 'dh_feature'    and rg.bundle = 'watershed'    and st_contains(      st_setsrid(rg.dh_geofield_geom,4326), st_setsrid(mpg.dh_geofield_geom,4326)     )  )   left outer join dh_feature as rseg   on (rseg.hydroid = rg.entity_id)  where rseg.hydroid is not null    and rseg.ftype = 'vahydro'  -- limit to a single facility for testing  --  and fac.hydroid = 71956     and mp.bundle = 'intake'    and mp.fstatus <> 'abandoned'  group by fac.hydroid, mp.hydroid, fac.ftype, mp.name);

create or replace temp view tmp_exemption_category as select a.propcode,
  case 
    when b.fstatus = 'abandoned' then b.fstatus 
    ELSE 'active' 
  END as fstatus,  
  count(a.*) as num_intakes,   
  round(sum(a.propvalue)::numeric,2) as ex_value,   
  CASE
    WHEN b.ftype like '%power%' THEN 'power'    
    ELSE 'non-power'  
  END as pnp,   
  c.tnt
from dh_properties as a 
left outer join dh_feature as b 
on (  a.featureid = b.hydroid   and a.entity_type = 'dh_feature') 
left outer join tmp_mp_riverseg as c
on (  c.hydroid = b.hydroid ) 
where propname = 'vwp_exempt_mgd'   
and entity_type = 'dh_feature'   
and b.bundle = 'intake'  
--and b.fstatus <> 'abandoned'
group by propcode, pnp, b.fstatus, c.tnt
order by pnp, propcode, b.fstatus DESC;

-- total by category of exempt/permitted max value
create temp view tmp_exempt_formatted as 
select pnp, fstatus, sum(num_intakes) as num_intakes,  
  CASE     
    WHEN propcode like '401%' THEN '401 Certification'    
    WHEN propcode like 'vwp%' THEN 'VWP Permit'    
    WHEN propcode like 'safe%' THEN 'Safe Yield/1Q30'    
    WHEN propcode like 'vdh%' THEN 'VDH Capacity'    
    WHEN propcode like 'pre%' THEN 'Pre-1989'    
    WHEN propcode like 'intake%' THEN 'Intake Capacity'    
    WHEN propcode like 'rfi%' THEN 'RFI 2009'    
    WHEN propcode = 'wd_mgy_max_pre1990'  THEN 'Pre-1989'    
    ELSE 'Non-Permitted, Non-Exempt'  
  END as est_type, tnt,  
  sum(ex_value) as ex_total
from tmp_exemption_category 
group by pnp, est_type, fstatus, tnt
order by tnt, pnp;


select tnt, est_type, sum(num_intakes) as num_intakes, sum(ex_total) as ex_total
from tmp_exempt_formatted 
where fstatus <> 'abandoned' 
and tnt is not null 
group by tnt, est_type
order by tnt, est_type ;

select tnt, est_type, sum(num_intakes) as num_intakes, round(sum(ex_total)) as ex_total
from tmp_exempt_formatted 
where fstatus <> 'abandoned' 
and tnt is not null 
group by tnt, est_type
order by tnt, est_type ;

select tnt, est_type, sum(num_intakes) as num_intakes, round(sum(ex_total)) as ex_total
from tmp_exempt_formatted where fstatus <> 'abandoned' and tnt is not null 
group by tnt, est_type
order by tnt, est_type ;


select tnt, est_type, sum(num_intakes) as num_intakes, round(sum(ex_total)) as ex_total
from tmp_exempt_formatted 
where fstatus <> 'abandoned' 
and tnt = 'non-power'
group by tnt, est_typeorder by tnt, est_type ;

select tnt, est_type, sum(num_intakes) as num_intakes, round(sum(ex_total)) as ex_total
from tmp_exempt_formatted
where fstatus <> 'abandoned'
and tnt = 'non-tidal'
group by tnt, est_type
order by tnt, est_type ;

select 'Tidal' as "Stream Type", est_type as "Exemption Data Source Type", 
sum(num_intakes) as num_intakes, 
round(sum(ex_total)) as ex_total
from tmp_exempt_formatted
where fstatus <> 'abandoned'and tnt = 'tidal'
group by tnt, est_typeorder by tnt, est_type ;


-- uncomment the next line to output as latex
\pset format latex
-- Non tidal 
select 'Non-Tidal' as "Stream Type", 
est_type as "Scenario Data Source Type", 
sum(num_intakes) as "No. of Intakes", 
round(sum(ex_total)) as "Total (mgd)"
from tmp_exempt_formatted
where fstatus <> 'abandoned'
and tnt = 'non-tidal'
group by tnt, est_type
order by tnt, est_type ;

-- Tidal 
select 'Tidal' as "Stream Type", 
est_type as "Scenario Data Source Type", 
sum(num_intakes) as "No. of Intakes", 
round(sum(ex_total)) as "Total (mgd)"
from tmp_exempt_formatted
where fstatus <> 'abandoned'
and tnt = 'tidal'
group by tnt, est_type
order by tnt, est_type ;
