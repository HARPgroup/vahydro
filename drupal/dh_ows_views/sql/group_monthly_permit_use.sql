CREATE or REPLACE VIEW view_dh_ows_monthly_group_permit_use as (
  (
    select extract(epoch from q.mstart)::bigint as month_start, 
      extract(epoch from q.mend)::bigint AS month_end, 
      extract(year from q.mstart) as cal_year,
      extract(month from q.mstart) as cal_month,
      a.adminid, 
      b.varkey, b.hydroid as varid, rv.varkey as rep_varkey, 
      c.propname, c.pid, c.propvalue as limit_gpmo, e.proptext_value as proptext, 
      sum(ts.tsvalue) as total_gpmo
    from (
      select mstart, (mstart + interval '1 month' - interval '1 day') as mend  
      from (
        SELECT * FROM generate_series('1950-01-01'::timestamp,
        (extract(year from now()) || '-12-01')::timestamp, '1 months') as mstart
      ) as a
    ) as q
    left outer join dh_adminreg_feature as a 
    on (1 = 1)
    left outer join dh_variabledefinition as b 
    on (
      b.varkey in ('wd_limit_group_gpmo')
    )
    left outer join dh_properties as c 
    on (c.varid = b.hydroid 
      and c.featureid = a.adminid
      -- added to support tiered permit rules
      and (
        (
        c.enddate >= extract(epoch from q.mstart) 
        and c.startdate <=  extract(epoch from q.mend) 
        )
        OR 
        (
        c.enddate is null
        and c.startdate is null
        )
      )
    ) 
    left outer join field_data_dh_link_admin_pr_condition as permlink 
    on (
      c.pid = permlink.entity_id
    )
    left outer join dh_feature as mp 
    on (
      permlink.dh_link_admin_pr_condition_target_id = mp.hydroid
    )
    left outer join dh_variabledefinition as rv 
    on (
      rv.varkey in ('wlg', 'wl')
    )
    left outer join dh_timeseries as ts 
    on (ts.featureid = mp.hydroid
      and ts.varid = rv.hydroid 
      -- tstime specifies the due date for these events 
      -- tsendtime specifies the received date
      and tstime >= extract(epoch from q.mstart) 
      and tstime <=  extract(epoch from q.mend) 
    ) 
    left outer join field_data_proptext as e 
    on (c.pid = e.entity_id
    )
    where  ( c.pid is not null )
    and (
      (rv.varkey = 'wlg' and b.varkey = 'wd_limit_group_gpmo')
      or (rv.varkey = 'wl' and b.varkey = 'wd_limit_group_mgmo')
    ) 
    and (c.propname is not null)
    group by q.mstart, q.mend, a.adminid, b.varkey, rv.varkey, b.hydroid, c.propname, c.pid, c.propvalue, e.proptext_value 
    order by q.mstart 
  )
);