require("dplyr")
require('httr')
require("sqldf")

#----------------------------------------------
# USER INPUTS
#
basepath <- 'http://deq2.bse.vt.edu/d.dh/'
y = 2018
export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020"

#----------------------------------------------

#pulls directly from map export view BUT locality = NA for all rows
   print(y)
   startdate <- paste(y, "-01-01",sep='')
   enddate <- paste(y, "-12-31", sep='')
 vwp <- '91200'
 gwp <- '65668'
 vwuds <- '77498'
 
 #no filter on permit authority
   localpath <- tempdir()
   filename <- paste("data.all_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(basepath,"ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B%5D=well&bundle%5B%5D=intake&dh_link_admin_reg_issuer_target_id%5B%5D=65668&dh_link_admin_reg_issuer_target_id%5B%5D=91200&dh_link_admin_reg_issuer_target_id%5B%5D=77498",sep=""), destfile = destfile, method = "libcurl")
   data.all <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")

   data_all <- data.all
 #VWP
   localpath <- tempdir()
   filename <- paste("data.vwp_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(basepath,"ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B1%5D=intake&dh_link_admin_reg_issuer_target_id%5B0%5D=",vwp,sep=""), destfile = destfile, method = "libcurl")
   data_vwp <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
 #GWP
   localpath <- tempdir()
   filename <- paste("data.gwp_",y,".csv",sep="")
   destfile <- paste(localpath,filename,sep="\\")
   download.file(paste(basepath,"ows-awrr-map-export/wd_mgy?ftype_op=not&ftype=hydropower&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B0%5D=well&dh_link_admin_reg_issuer_target_id%5B0%5D=",gwp,sep=""), destfile = destfile, method = "libcurl")
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

count_has_permit <- sqldf("Select count(MP_hydroid)
                      from mp_permits
                      where GWP_permit IS NOT NULL")

data_base_facility <- sqldf("SELECT Facility_hydroid, GWP_permit, VWP_permit
                            FROM mp_permits
                            GROUP BY Facility_hydroid")
write.csv(mp_permits, file = paste0(export_path, "mp_permits.csv"))

  
  
