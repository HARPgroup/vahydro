select * from (
  select a.hydroid, a.name, 
    extract(year from to_timestamp(b.tstime)),
    b.tsvalue as annual,
    sum(c.tsvalue) as monthly
  from dh_feature as a
  left outer join dh_timeseries as b 
  on (
    a.hydroid = b.featureid
    and b.entity_type = 'dh_feature'
    and b.varid = 305
  )
  left outer join dh_timeseries as c
  on (
    a.hydroid = c.featureid
    and c.entity_type = 'dh_feature'
    and c.varid = 1021
  )
  where a.bundle in ('well', 'intake')
  and extract(year from to_timestamp(b.tstime)) = 2021
  and extract(year from to_timestamp(c.tstime)) = 2021
  group by a.hydroid, a.name, b.tsvalue, extract(year from to_timestamp(b.tstime))
) as foo
where (
  (annual > 1.01 * monthly )
  or (annual < 0.99 * monthly )
)
;
