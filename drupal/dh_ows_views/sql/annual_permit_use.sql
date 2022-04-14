CREATE or REPLACE VIEW view_dh_ows_annual_permit_use as (
  (
    select extract(epoch from q.pstart)::bigint as year_start, extract(epoch from q.pend)::bigint AS year_end, extract(year from q.pstart) as cal_year,
      a.adminid, 
      b.varkey, b.hydroid as varid, rv.varkey as rep_varkey, 
      c.propname, c.pid, c.propvalue as limit_gpy, e.proptext_value as proptext, 
      sum(ts.tsvalue) as total_gpy
    from (
      select (pyear || '-01-01')::date as pstart, (pyear || '-12-31')::date as pend  
      from (
        SELECT * FROM generate_series(1950,
        (extract(year from now()))::integer, 1) as pyear
      ) as a
    ) as q
    left outer join dh_adminreg_feature as a 
    on (1 = 1)
    left outer join dh_variabledefinition as b 
    on (
      b.varkey in ('wd_limit_gpy')
    )
    left outer join dh_properties as c 
    on (c.varid = b.hydroid 
     and c.featureid = a.adminid
      -- added to support tiered permit rules
      and (
        (
        c.enddate >= extract(epoch from q.pstart) 
        and c.startdate <=  extract(epoch from q.pend) 
        )
        OR 
        (
        c.enddate is null
        and c.startdate is null
        )
      )
    ) 
    left outer join field_data_dh_link_admin_location as permlink 
    on (
      a.adminid = permlink.dh_link_admin_location_target_id 
    )
    left outer join dh_feature as fac 
    on (
      fac.hydroid = permlink.entity_id 
    )
    left outer join field_data_dh_link_facility_mps as link 
    on (
      fac.hydroid = link.dh_link_facility_mps_target_id
    )
    left outer join dh_feature as mp 
    on (
      link.entity_id = mp.hydroid
    )
    left outer join dh_variabledefinition as rv 
    on (
      rv.varkey in ('wlg')
    )
    left outer join dh_timeseries as ts 
    on (ts.featureid = mp.hydroid
      and ts.varid = rv.hydroid 
      -- tstime specifies the due date for these events 
      -- tsendtime specifies the received date
      and tstime >= extract(epoch from q.pstart) 
      and tstime <=  extract(epoch from q.pend) 
    ) 
    left outer join field_data_proptext as e 
    on (c.pid = e.entity_id
    )
    where (1 = 1 )
    and (
      (rv.varkey = 'wlg' and b.varkey = 'wd_limit_gpy')
      or (rv.varkey = 'wl' and b.varkey = 'wd_limit_mgy')
    ) 
    and (c.propname = b.varkey)
    group by q.pstart, q.pend, a.adminid, b.varkey, rv.varkey, b.hydroid, c.propname, c.pid, c.propvalue, e.proptext_value 
    order by q.pstart 
  )
);