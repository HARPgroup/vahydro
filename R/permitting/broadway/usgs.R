basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library('dataRetrieval')

gage_number = '01633000'
startdate = '1900-01-01'
enddate = '2022-12-31'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
om_flow_table(gage_data, 'flow')

available_mgd <- gage_data
available_mgd$available_mgd <- (available_mgd$flow * 0.1) / 1.547
avail_table = om_flow_table(available_mgd, 'available_mgd')
kable(avail_table, 'markdown')

