require(sqldf)
#require(rgdal)
require(httr)

#----------------------------------------------
# USER INPUTS

basepath <- 'http://deq2.bse.vt.edu/d.dh/'
y = 2018

export_date <- Sys.Date()
export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020"
#----------------------------------------------

#prevents scientific notation
options(scipen = 20)
#QA Check for demand projections (for Aquaveo export and SWRP update)

# gwma_path <- "U:\\OWS\\GIS\\GWMA\\gwma_all-2015"
# gwma_layer_name <- "gwma_all-2015"

#pull directly from VAHydro export url

#wd_current_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wd_current_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
wdcurrent_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")

wdcurrent <- wdcurrent_load

#filters used: active, well, prop_name
#wsp2020_2020_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2020_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
well_wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
well_wsp2020 <- well_wsp2020_load

#filters used: active, intake, prop_name
#wsp2020_2020_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=intake&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2020_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
intake_wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
intake_wsp2020 <- intake_wsp2020_load

## Union well and intake
wsp2020 <- sqldf(
  "select * from well_wsp2020
  UNION 
  select * from intake_wsp2020
  "
)

################# Virtual Facilities Data Summary ####################################
#virtual facilities represent county-wide estimates - each county has a wsp_category facility and 2 MPs (SW & GW) (except SSU has only GW MP) 
localpath <- tempdir()
filename <- paste("data_vf2020.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=All&propname_op=%3D&propname=wsp2020_2020_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=wsp",sep=""), destfile = destfile, method = "libcurl")
vf_wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
vf_wsp2020 <- vf_wsp2020_load

## Union virtual and non-virtual
wsp2020 <- sqldf(
  "select * from wsp2020
  UNION 
  select * from vf_wsp2020
  "
)

# Now get 2040 values
#well_wsp2020_2040_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
well_wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
well_wsp2040 <- well_wsp2040_load

#intake_wsp2020_2040_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=intake&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
intake_wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
intake_wsp2040 <- intake_wsp2040_load

## Union well and intake
wsp2040 <- sqldf(
  "select * from well_wsp2040
  UNION 
  select * from intake_wsp2040
  "
)

#virtual facilities represent county-wide estimates - each county has a wsp_category facility and 2 MPs (SW & GW) (except SSU has only GW MP) 
localpath <- tempdir()
filename <- paste("data_vf2040.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=All&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=wsp",sep=""), destfile = destfile, method = "libcurl")
vf_wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
vf_wsp2040 <- vf_wsp2040_load

## Union virtual and non-virtual
wsp2040 <- sqldf(
  "select * from wsp2040
  UNION 
  select * from vf_wsp2040
  "
)

#merge wsp2020 and wsp2040 tables
wsp2020_2040 <- sqldf(
  "select a.*, a.mp_share as mp_2020_mgy, 
     b.fac_value as fac_value_2040, 
     b.mp_share as mp_share_2040,
      CASE
        WHEN a.facility_ftype in ('agriculture', 'irrigation') 
          THEN 'wsp_plan_system-ssuag'
        WHEN a.facility_ftype in ('manufacturing', 'nuclearpower', 'mining', 
          'commercial', 'industrial', 'fossilpower', 'hydropower') 
          THEN 'wsp_plan_system-ssulg'
        WHEN a.facility_ftype in ('municipal') 
          THEN 'wsp_plan_system-cws'
          ELSE a.facility_ftype
      END as wsp_ftype
  from wsp2020 as a 
  left outer join wsp2040 as b 
  on (
    a.MP_hydroid = b.MP_hydroid
  )
")


# Eliminate all scientific notation errors by re-apportioning
wsp2020_2040$mp_share = wsp2020_2040$facility_use_fraction * wsp2020_2040$fac_value
wsp2020_2040$mp_2020_mgy <- wsp2020_2040$mp_share
wsp2020_2040$mp_share_2040 = wsp2020_2040$facility_use_fraction * wsp2020_2040$fac_value_2040
wsp2020_2040$mp_2040_mgy <- wsp2020_2040$mp_share_2040
wsp2020_2040$delta_2040_mgy <- (wsp2020_2040$mp_2040_mgy - wsp2020_2040$mp_2020_mgy)
wsp2020_2040$delta_2040_pct <- (wsp2020_2040$mp_2040_mgy - wsp2020_2040$mp_2020_mgy) / wsp2020_2040$mp_2040_mgy


# Write this file
write.csv(wsp2020_2040, file=paste(export_path,'wsp2020.mp.all.csv',sep='\\' ))

# Aggregate by Facility
a_lets_see <- sqldf("SELECT *
                    FROM wsp2020_2040
                    where facility_long IS NULL")

wsp_facility_2020_2040 <- sqldf(
  " select Facility_hydroid, facility_name, facility_ftype, fips_code, 
      CASE
        WHEN facility_lat IS NULL
          THEN avg(Latitude)
        WHEN abs(facility_lat) < 35
          THEN avg(Latitude)
        WHEN abs(facility_lat) > 41
          THEN avg(Latitude)
        ELSE facility_lat
        END as Latitude2,
      CASE
        WHEN facility_long IS NULL
          THEN avg(Longitude)
        WHEN abs(facility_long) > 84
          THEN avg(Longitude)
        WHEN abs(facility_long) < 75
          THEN avg(Longitude)
        ELSE facility_long
        END as Longitude2,
      sum(mp_2020_mgy) as fac_2020_mgy,
      sum(mp_2040_mgy) as fac_2040_mgy,
      CASE
        WHEN facility_ftype in ('agriculture', 'irrigation') 
          THEN 'wsp_plan_system-ssuag'
        WHEN facility_ftype in ('manufacturing', 'nuclearpower', 'mining', 
          'commercial', 'industrial', 'fossilpower', 'hydropower') 
          THEN 'wsp_plan_system-ssulg'
        WHEN facility_ftype in ('municipal') 
          THEN 'wsp_plan_system-cws'
          ELSE facility_ftype
      END as wsp_ftype
    from wsp2020_2040 
    group by Facility_hydroid, facility_name, facility_ftype
  "
)

# Write this file
write.csv(wsp_facility_2020_2040, file=paste(export_path,'wsp2020.fac.all.csv',sep='\\' ))


# SURFACE WATER Aggregate by Facility
SW_facility_2020_2040 <- sqldf(
  " select Facility_hydroid, facility_name, facility_ftype, fips_code, 
      avg(Latitude) as Latitude, avg(Longitude) as Longitude,
      sum(mp_2020_mgy) as fac_2020_mgy,
      sum(mp_2040_mgy) as fac_2040_mgy
    from wsp2020_2040 
    where MP_bundle = 'intake'
    group by Facility_hydroid, facility_name, facility_ftype
  "
)

# Write this file
write.csv(SW_facility_2020_2040, file=paste(export_path,'SW.fac.all.csv',sep='\\' ))


# GROUNDWATER Aggregate by Facility
GW_facility_2020_2040 <- sqldf(
  " select Facility_hydroid, facility_name, facility_ftype, fips_code, 
      avg(Latitude) as Latitude, avg(Longitude) as Longitude,
      sum(mp_2020_mgy) as fac_2020_mgy,
      sum(mp_2040_mgy) as fac_2040_mgy
    from wsp2020_2040 
    where MP_bundle = 'well'
    group by Facility_hydroid, facility_name, facility_ftype
  "
)

# Write this file
write.csv(GW_facility_2020_2040, file=paste(export_path,'GW.fac.all.csv',sep='\\' ))

#to generate export for Groundwater Modeling (send to aquaveo), go to gw_model_file_create.R at the bottom


