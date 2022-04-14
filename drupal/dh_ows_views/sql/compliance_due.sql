CREATE or REPLACE VIEW view_dh_ows_compliance_due as (
(
  -- quarterly items
  select extract(epoch from q.due_start)::bigint as due_start, extract(epoch from q.due_end)::bigint AS due_end, q.due_quarter,
    q.due_week, q.due_month, q.due_day, q.due_year,
    a.adminid, 
    b.varkey, 
    c.propname, c.pid, c.propvalue, e.proptext_value as proptext, 
    d.tid, d.varid, 
    CASE 
      WHEN d.tstime is null THEN extract(epoch from (q.due_year || '-' || lpad(q.due_month::varchar,2,'0') || '-10 00:00:00 EST')::timestamp)::bigint
      ELSE d.tstime 
    END as due_date, 
    d.tsendtime as date_received
  from (
    select a.qstart as due_start, a.qstart + interval '3 months' - interval '1 day' as due_end, 
      extract (quarter from qstart) as due_quarter,
      extract (week from qstart) as due_week, extract (month from qstart) as due_month,
      extract (day from qstart) as due_day, extract (year from qstart) as due_year 
    from (
      SELECT * FROM generate_series('1950-01-01'::timestamp,
      (extract(year from now()) || '-12-31')::timestamp, '3 months') as qstart
    ) as a
  ) as q
  left outer join dh_adminreg_feature as a 
  on (1 = 1)
  left outer join dh_variabledefinition as b 
  on (
    b.varkey in ('vadeq_report_wl', 'vadeq_report_wq', 'vadeq_report_wd')
  )
  left outer join dh_properties as c 
  on (c.varid = b.hydroid 
   and c.featureid = a.adminid
  )
  left outer join dh_timeseries as d 
  on (d.featureid = a.adminid
    and d.varid = c.varid 
    -- tstime specifies the due date for these events 
    -- tsendtime specifies the received date
    and tstime >= extract(epoch from q.due_start) 
    and tstime <=  extract(epoch from q.due_end) 
  ) 
  left outer join field_data_proptext as e 
  on (c.pid = e.entity_id
  )
  where (1 = 1)
  -- propname is not null insures that this condition is required
    AND c.propname is not null 
    AND (
      ( 
        (e.proptext_value = 'quarterly')
        and ( 
          (c.propvalue in (1,2,3,4) and (c.propvalue = q.due_quarter))
          OR (c.propvalue = 5 and (q.due_quarter in (1,3)) )
          OR (c.propvalue = 6 and (q.due_quarter in (2,4)) )
          OR (c.propvalue = 7 and (q.due_quarter in (1,2)) )
          OR (c.propvalue = 8 and (q.due_quarter in (2,3)) )
          OR (c.propvalue = 9 and (q.due_quarter in (3,4)) )
          OR (c.propvalue = 10 and (q.due_quarter in (1,4)) )
          OR (c.propvalue is null )
          OR (c.propvalue = 0 )
        )
      )
      OR (
      -- annual reporting conditions harmonize OK with quarterly
        (e.proptext_value = 'annual')
        and ( 
          (c.propvalue in (1,2,3,4) and (c.propvalue = q.due_quarter))
          OR (c.propvalue is null )
        )
      )
      OR 
      ( 
        (e.proptext_value = 'biannual')
        and ( 
          (c.propvalue in (1,2,3,4) and (c.propvalue = q.due_quarter))
          OR (c.propvalue = 5 and (q.due_quarter in (1,3)) )
          OR (c.propvalue = 6 and (q.due_quarter in (2,4)) )
          OR (c.propvalue = 7 and (q.due_quarter in (1,2)) )
          OR (c.propvalue = 8 and (q.due_quarter in (2,3)) )
          OR (c.propvalue = 9 and (q.due_quarter in (3,4)) )
          OR (c.propvalue = 10 and (q.due_quarter in (1,4)) )
          OR (c.propvalue is null )
        )
      )
    )
  order by d.tstime
)
-- union monthly
);