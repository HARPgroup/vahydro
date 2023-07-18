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
fac_elid <- 353097
runid <- 401

rdat <- om_get_rundata(r_elid, runid, site = omsite)
rodat <- om_get_rundata(ro_elid, runid, site = omsite)
facdat <- om_get_rundata(fac_elid, runid, site = omsite)


kable(om_flow_table(rdat, "Qout"))

rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600'),
  'metric' = c('Runit','Runit'),
  'runlabel' = c('Runit_perm', 'Runit_600')
)
# note we specify cbp532_lrseg because this southern rivers
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp532_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: 
rnk_rodata = fn_extract_basin(ro_data,'OR3_7740_8271')


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


