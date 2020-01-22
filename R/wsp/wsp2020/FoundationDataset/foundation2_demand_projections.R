require(sqldf)
#require(rgdal)
require(httr)

#----------------------------------------------
# USER INPUTS

basepath <- 'http://deq2.bse.vt.edu/d.dh/'
y = 2018

export_date <- Sys.Date()

#JanetOriginalCode saved to common drive in data dev mngmt folder
##export_path <- "U:\\OWS\\Data Development_Management\\Data Requests\\Aquaveo\\QA_check_2019\\"
export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\"

#foundation1_mp_permits.R script writes the mp_permits.csv (aka the has_permits table)
load_path <- paste0(export_path, "2020-01-22_mp_permits.csv")
#----------------------------------------------

#prevents scientific notation
options(scipen = 20)
#QA Check for demand projections (for Aquaveo export and SWRP update)

# #load in exports
# ##export_path <- "U:\\OWS\\Data Development_Management\\Data Requests\\Aquaveo\\QA_check_2019\\"
# export_path <- "U:\\OWS\\Report Development\\2020 State Water Resource Update\\2020_Dataset_QA\\"

#use either sys.date OR date of when export was downloaded and is in title of export
#export_date <- Sys.Date()

data_base <- read.csv(file = load_path, header = T, sep = ",")

#use either sys.date OR date of when export was downloaded and is in title of export
export_date <- Sys.Date()

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
wsp2020_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
wsp2020 <- wsp2020_load

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
#wsp2020_2040_mgy
localpath <- tempdir()
filename <- paste("data.all.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus_op=in&fstatus=active&propname_op=%3D&propname=wsp2020_2040_mgy&hydroid_1_op=%3D&hydroid_1%5Bvalue%5D=&hydroid_1%5Bmin%5D=&hydroid_1%5Bmax%5D=&dh_link_admin_fa_usafips_target_id_op=in&ftype_op=contains&ftype=",sep=""), destfile = destfile, method = "libcurl")
wsp2040_load <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
wsp2040 <- wsp2040_load
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
     b.mp_share as mp_share_2040
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


# Join in Programatic information / i.e., permits and planning registrations
join_permits <- sqldf("SELECT *
                      FROM wsp2020_2040 as a
                      left outer join data_base as b
                      ON a.MP_hydroid = b.MP_hydroid")

# Write this fileS
write.csv(wsp2020_2040, file=paste(export_path, Sys.time(),'_wsp2020.mp.all.csv',sep='' ))
write.csv(join_permits, file=paste(export_path,'_join_permits.csv',sep='' ))

# Aggregate by Facility
wsp_facility_2020_2040 <- sqldf(
  " select Facility_hydroid, facility_name, facility_ftype, fips_code, 
      avg(Latitude) as Latitude, avg(Longitude) as Longitude,
      sum(mp_2020_mgy) as fac_2020_mgy,
      sum(mp_2040_mgy) as fac_2040_mgy
    from wsp2020_2040 
    group by Facility_hydroid, facility_name, facility_ftype
  "
)
write.csv(wsp_facility_2020_2040, file=paste(export_path,'wsp2020.fac.all.csv',sep='\\' ))

