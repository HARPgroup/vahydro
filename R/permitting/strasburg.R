
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library('dataRetrieval')

relid = 230667


gage_number = '01633000' # Mount J
startdate = '1984-01-01'
enddate = '2022-12-31'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
mountj <- om_flow_table(gage_data, 'flow')
mountj

gage_number = '01634000' # Strasburg
startdate = '1984-01-01'
enddate = '2022-12-31'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
strasb <- om_flow_table(gage_data, 'flow')
strasb

cmpsmj <- strasb
cmpsmj[1:12,2:8] <- strasb[1:12,2:8] / mountj[1:12,2:8]
cmpsmj[1:12,2:8] <- round(cmpsmj[1:12,2:8],1)

knitr::kable(mountj,'markdown')
knitr::kable(strasb,'markdown')
knitr::kable(cmpsmj,'markdown')

rdat <- om_get_rundata(relid, 400, site=omsite)
max(rdat$year)
quantile(rdat$wd_cumulative_mgd)
quantile(rdat$ps_cumulative_mgd)
om_flow_table(rdat, 'Qout')
