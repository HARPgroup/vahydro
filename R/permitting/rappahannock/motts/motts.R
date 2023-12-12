library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Motts fac
mfelid = 322005
mrelid = 352157 
hrelid = 352159 
runid = 401
datmf <- om_get_rundata(mfelid, runid, site = omsite)
datm <- om_get_rundata(mrelid, runid, site = omsite)
dath <- om_get_rundata(hrelid, runid, site = omsite)
om_flow_table(datm,"ps_refill_pump_mgd")
om_flow_table(dath,"ps_refill_pump_mgd")

r_stats <- om_quantile_table(
  dath, 
  metrics = c(
    "Qout", "Qrapidan", "available_mgd", "ps_refill_pump_mgd", "impoundment_use_remain_mg", "impoundment_demand", "system_urm", "hr_urm"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

r_stats <- om_quantile_table(
  datm, 
  metrics = c(
    "Qout", "Qrapidan", "available_mgd", "ps_refill_pump_mgd", "impoundment_use_remain_mg", "impoundment_demand", "system_urm", "hr_urm"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')


# river
relid = 258123 # Rapidan
datrap <- om_get_rundata(relid, 400, site = omsite)
rpid = 6605616
hrelid = 352159
mrelid = 352157
dathr401 <- om_get_rundata(hrelid, 401, site = omsite)
datmr401 <- om_get_rundata(mrelid, 401, site = omsite)
quantile(datmr401$wd_hr_mgd)
quantile(datmr401$wd_mr_mgd)
quantile(datmr401$wd_hr_mgd + datmr401$wd_mr_mgd)
quantile(datmr401$child_wd_mgd)
quantile(datmr401$system_urm)


# HR Rapp adjusted flow
elid = 258123 #Rappahannock River @ Fall Line RU5_6030_0001
gage_number = "01667500"
startdate <- "1984-10-01"
enddate <- "2014-09-30"
pstartdate <- "2008-04-01"
penddate <- "2008-11-30"

runid = 1131
finfo = fn_get_runfile_info(elid, runid, 37, site= omsite)
hdat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mode(hdat) <- 'numeric'
# Hourly to Daily flow timeseries
hdat = aggregate(
  hdat,
  as.POSIXct(
    format(
      time(hdat),
      format='%Y/%m/%d'),
    tz='UTC'
  ),
  'mean'
)

# Get and format gage data
gage_data <- dataRetrieval::readNWISdv(gage_number,'00060')
#gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$Date,tz="EST"))
#mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$Date)
om_flow_table(gage_data, 'X_00060_00003')
available_mgd <- gage_data
available_mgd$available_mgd <- (available_mgd$X_00060_00003 * 0.05) / 1.547
avail_table = om_flow_table(available_mgd, 'available_mgd')
kable(avail_table, 'markdown')
qflextable(avail_table)

#limit to hourly model period
hstart <- min(index(hdat))
hend <- max(index(hdat))
gagehdat <- window(gage_data, start = hstart, end = hend)
