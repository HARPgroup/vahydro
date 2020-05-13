require(sqldf)
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
 

################# Load Exempt Users export ##################################################
exempt <- read.csv("U:/OWS/foundation_datasets/wsp/wsp2020/ows-exemptions-export.csv")

################# wd_current_mgy Facilities Data Summary ####################################

localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
# Load Well current MGY
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wd_current_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
wdcurrent_gw <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
wdcurrent_load <- wdcurrent_gw # this retains backward compatibility, but we should update gw_model_file_create.R and others to filter by MP ftype
wdcurrent <- wdcurrent_load

#------------------------------------------------------------------------------------------------#

# load Intakes current MGY
download.file("http://deq2.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=intake&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wd_current_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=", destfile = destfile, method = "libcurl")
wdcurrent_sw <- read.csv(file=destfile, header=TRUE, sep=",")

#------------------------------------------------------------------------------------------------#

## Union well and intake
wdcurrent_all <- sqldf(
  "select * from wdcurrent_gw
  UNION
  select * from wdcurrent_sw"
)

write.csv(wdcurrent_all, file=paste(export_path,'wwr2018.mp.all.csv',sep='\\' ))

#------------------------------------------------------------------------------------------------#

# Aggregate by Facility
facility_current_all <- sqldf(
  " select Facility_hydroid, facility_name, facility_ftype, fips_code, 
      facility_lat, facility_long,
      sum(fac_value * facility_use_fraction) as wd_current_mgy,
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
    from wdcurrent_all 
    group by Facility_hydroid, facility_name, facility_ftype, fips_code, 
      facility_lat, facility_long
  "
)
write.csv(facility_current_all, file=paste(export_path,'wwr2018.fac.all.csv',sep='\\' ))

################# wsp_2020_2020 Facilities Data Summary ####################################

#filters used: active, well, prop_name
#wsp2020_2020_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2020_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
well_wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
well_wsp2020 <- well_wsp2020_load

#------------------------------------------------------------------------------------------------#

#filters used: active, intake, prop_name
#wsp2020_2020_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=intake&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2020_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
intake_wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
intake_wsp2020 <- intake_wsp2020_load

#------------------------------------------------------------------------------------------------#

## Union well and intake
wsp2020 <- sqldf(
  "select * from well_wsp2020 where facility_use_fraction != 0
  UNION 
  select * from intake_wsp2020 where facility_use_fraction != 0
  ")

################# wsp_2040_2020 Facilities Data Summary ####################################

#well_wsp2020_2040_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
well_wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
well_wsp2040 <- well_wsp2040_load

#------------------------------------------------------------------------------------------------#

#intake_wsp2020_2040_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=intake&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
intake_wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
intake_wsp2040 <- intake_wsp2040_load

#------------------------------------------------------------------------------------------------#

## Union well and intake
wsp2040 <- sqldf(
  "select * from well_wsp2040 where facility_use_fraction != 0
  UNION 
  select * from intake_wsp2040 where facility_use_fraction != 0
  ")

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

#------------------------------------------------------------------------------------------------#

# Eliminate all scientific notation errors by re-apportioning
wsp2020_2040$mp_share = wsp2020_2040$facility_use_fraction * wsp2020_2040$fac_value
wsp2020_2040$mp_2020_mgy <- wsp2020_2040$mp_share
wsp2020_2040$mp_share_2040 = wsp2020_2040$facility_use_fraction * wsp2020_2040$fac_value_2040
wsp2020_2040$mp_2040_mgy <- wsp2020_2040$mp_share_2040
wsp2020_2040$delta_2040_mgy <- (wsp2020_2040$mp_2040_mgy - wsp2020_2040$mp_2020_mgy)
wsp2020_2040$delta_2040_pct <- ((wsp2020_2040$mp_2040_mgy - wsp2020_2040$mp_2020_mgy) / wsp2020_2040$mp_2020_mgy)*100
wsp2020_2040$mp_2030_mgy <- (wsp2020_2040$mp_2020_mgy + wsp2020_2040$mp_2040_mgy)/2

wsp2020_2040 <- sqldf("SELECT MP_hydroid, 
                    MP_bundle,
                    CASE
        WHEN MP_bundle in ('intake') 
          THEN 'Surface Water'
        WHEN MP_bundle in ('well') 
          THEN 'Groundwater'
          ELSE MP_bundle
      END as source_type,
                    mp_status,
                    MPID,
                    Latitude, 
                    Longitude,
                    Facility_hydroid,
                    facility_name,
                    facility_status,
                    facility_ftype,
                    fips_Code,
                    facility_lat,
                    facility_long,
                    wsp_ftype,
                    CASE
        WHEN wsp_ftype in ('wsp_plan_system-ssuag') 
          THEN 'Agriculture'
        WHEN wsp_ftype in ('wsp_plan_system-ssulg') 
          THEN 'Large Self-Supplied User'
        WHEN wsp_ftype in ('wsp_plan_system-cws') 
          THEN 'Municipal'
        WHEN wsp_ftype in ('wsp_plan_system-ssusm') 
          THEN 'Small Self-Supplied User'
          ELSE wsp_ftype
      END as system_type,
                    mp_2020_mgy,
                    mp_2030_mgy,
                    mp_2040_mgy, 
                    delta_2040_mgy, 
                    delta_2040_pct
             FROM wsp2020_2040
             WHERE facility_status != 'unknown'")

#append exempt values 
wsp2020_2040 <- sqldf('SELECT a.*, b.final_exempt_propcode, b.final_exempt_propvalue_mgd
                      FROM wsp2020_2040 a
                      LEFT OUTER JOIN exempt b
                      ON a.MP_hydroid = b.mp_hydroid
                      ')

# Write this file
write.csv(wsp2020_2040, file=paste(export_path,'wsp2020.mp.all.csv',sep='\\' ), row.names = F)

# count_dupes <- sqldf("SELECT count(facility_name) as facility_count, facility_name, MP_bundle, sum(mp_2020_mgy), sum(mp_2040_mgy)
#                      FROM wsp2020_2040
#                      GROUP BY facility_name, MP_bundle
#                      having count(facility_name) > 1
#                      AND sum(mp_2020_mgy) != 0")
# #------------------------------------------------------------------------------------------------#
#to generate export for Groundwater Modeling (send to aquaveo), go to gw_model_file_create.R at the bottom