require("dplyr")
require('httr')
require("sqldf")

#----------------------------------------------
# USER INPUTS
#
#----------------------------------------------
# Note: basepath variable is reserved for the local file system,
#       scripts should use 'site' as the variable to access vahydro
# site is defined in /var/www/config.R
# Example:
# site <- 'http://deq1.bse.vt.edu/d.dh'
y = 2018
# Note: export_path is defined in the users config.local.R file
#       which eliminates the need to change it in every file unless
#       a special export location is required
#export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\"
#----------------------------------------------
# Note: basepath variable is
basepath = "/var/www/R"
source("/var/www/R/config.R")
# Create datasource
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token(rest_pw)

#pulls directly from map export view BUT locality = NA for all rows
   print(y)
   startdate <- paste(y, "-01-01",sep='')
   enddate <- paste(y, "-12-31", sep='')
 vwp <- '91200'
 gwp <- '65668'
 vwuds <- '77498'

 #pulls all 3 (vwp, gwp, vwuds)
   localpath <- tempdir()
   filename <- paste("data.all_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(site,"/ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B%5D=well&bundle%5B%5D=intake&dh_link_admin_reg_issuer_target_id%5B%5D=65668&dh_link_admin_reg_issuer_target_id%5B%5D=91200&dh_link_admin_reg_issuer_target_id%5B%5D=77498",sep=""), destfile = destfile, method = "libcurl")
   data.all <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
   # Propose to use a method that supports REST authentication.
   url <- paste(
       site,"/ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",
       startdate,"&tstime%5Bmax%5D=",
       enddate,
       "&bundle%5B%5D=well&bundle%5B%5D=intake&dh_link_admin_reg_issuer_target_id",
       "%5B%5D=65668&dh_link_admin_reg_issuer_target_id",
       "%5B%5D=91200&dh_link_admin_reg_issuer_target_id%5B%5D=77498",sep="")
   data.all <- vahydro_auth_read(url, token)
   data_all <- data.all
 #VWP
   localpath <- tempdir()
   filename <- paste("data.vwp_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(site,"/ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B1%5D=intake&dh_link_admin_reg_issuer_target_id%5B0%5D=",vwp,sep=""), destfile = destfile, method = "libcurl")
   data_vwp <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
 #GWP
   localpath <- tempdir()
   filename <- paste("data.gwp_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(site,"/ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B0%5D=well&dh_link_admin_reg_issuer_target_id%5B0%5D=",gwp,sep=""), destfile = destfile, method = "libcurl")
   data_gwp <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")


mp_permits <- sqldf("select a.*, case when b.MP_hydroid IS NOT NULL
                  THEN 'GWP'
                  ELSE NULL END as GWP_permit,
                  case when c.MP_hydroid IS NOT NULL
                  THEN 'VWP'
                  ELSE NULL END as VWP_permit
                  FROM data_all as a
                  left outer join data_gwp as b
                  on (a.MP_hydroid = b.MP_hydroid)
                   left outer join data_vwp as c
                   on (a.MP_hydroid = c.MP_hydroid)")

write.csv(mp_permits, file = paste0(export_path, Sys.Date(), "_mp_permits.csv"), row.names = F)

#count GWP permit
sqldf("Select count(MP_hydroid)
                      from mp_permits
                      where GWP_permit IS NOT NULL")
#group by facility
# data_base_facility <- sqldf("SELECT Facility_hydroid, GWP_permit, VWP_permit
#                             FROM mp_permits
#                             GROUP BY Facility_hydroid")
#



