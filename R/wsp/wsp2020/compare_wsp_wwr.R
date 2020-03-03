
export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020"
wsp_facility_2020_2040 = read.csv(file=paste(export_path,'wsp2020.fac.all.csv',sep='\\' ))
wwr_facility_2020 = read.csv(file=paste(export_path,'wwr2020.fac.all.csv',sep='\\' ))

cmp_data_all = sqldf(
  "select a.Facility_hydroid, a.ftype, a.wsp_ftype, 
     a.wd_current_mgy, b.fac_2020_mgy, b.fac_2040_mgy
   from wwr_facility_2020 as a
   left outer join wsp_facility_2020_2040 as b 
   on (
     a.Facility_hydroid = b.Facility_hydroid
   )
  "
)

cmp_data_nonpower = sqldf(
  "select a.Facility_hydroid, a.ftype, a.wsp_ftype, 
     a.wd_current_mgy, b.fac_2020_mgy, b.fac_2040_mgy
   from wwr_facility_2020 as a
   left outer join wsp_facility_2020_2040 as b 
   on (
     a.Facility_hydroid = b.Facility_hydroid
   )
   where a.ftype not like '%power%'
  "
)

plot(wd_current_mgy ~ fac_2020_mgy, data=cmp_data_nonpower)
npreg <- lm(wd_current_mgy ~ fac_2020_mgy, data=cmp_data_nonpower)
summary(npreg)

qa_data_nonpower = sqldf(
  "select * from cmp_data_nonpower 
  where (  
    (fac_2020_mgy > (10 * wd_current_mgy))
    OR
    (fac_2020_mgy < (0.1 * wd_current_mgy))
  )
  AND (fac_2020_mgy > 0)
  AND (wd_current_mgy > 0)
  "
)
total_data_nonpower = sqldf(
  "select sum(wd_current_mgy) as wd_current_mgy, 
    sum(fac_2020_mgy) as fac_2020_mgy
    FROM cmp_data_nonpower
  "
)


qa_big_nonpower = sqldf(
  "select * from cmp_data_nonpower 
  where (fac_2020_mgy > 20000)
  OR (wd_current_mgy > 20000)
  "
)
