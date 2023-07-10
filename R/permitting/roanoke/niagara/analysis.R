library('hydrotools')
library('zoo')
library("IHA")
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)


################################################################################################
# LOAD MODEL IDs:
r_elid <- 252625 
ro_elid <- 245125 # 353007

runid <- 600

rdat <- om_get_rundata(r_elid, runid, site = omsite)
rodat <- om_get_rundata(ro_elid, runid, site = omsite)

kable(om_flow_table(rdat, "Qout"))



# USGS gage verify
gage_number = '02056000'
startdate = '1984-10-01'
enddate = '2020-09-30'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
gage_data
om_flow_table(gage_data, 'flow')
