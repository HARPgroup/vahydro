library('hydrotools')
library('zoo')
library("knitr")
library("rapportools")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)


flowdf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_0', 'runid_2', 'runid_600', 'runid_0', 'runid_2', 'runid_600'),
  'metric' = c('l90_Qout','l90_Qout','l90_Qout', 'l90_year', 'l90_year', 'l90_year'),
  'runlabel' = c('l90_0', 'l90_2', 'l90_600', 'l90_year_0', 'l90_year_2', 'l90_year_600')
)
# ftype options,
# sova: cbp532_lrseg
# others: cbp6_lrseg
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = flowdf, bundle = "watershed", ftype = "vahydro",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
roa_flow = fn_extract_basin(wshed_data,'OR7_8490_0000')


sqldf(
  "
  select riverseg 
  from roa_flow 
  where ( (l90_year_0 = 1984) or (l90_year_400 = 1984)) 
  "
)

# this *should* be a zero list if all is in order.
sqldf(
  "
  select riverseg
  from roa_flow 
  where ( l90_400 = 0) 
  "
)


avdat <- om_get_rundata(251403, 0, site=omsite)
avdatf <- as.data.frame(avdat)
sqldf("select year, avg(Qout) from avdatf group by year order by year")

avdat4 <- om_get_rundata(251403, 400, site=omsite)
avdatf4 <- as.data.frame(avdat4)
sqldf("select year, avg(Qout) from avdatf4 group by year order by year")

smldat2 <-om_get_rundata(252119, 2, site=omsite)
smldat4 <- om_get_rundata(252119, 400, site=omsite)
quantile(smldat2$Qin)
quantile(smldat4$Qin)
quantile(smldat2$Qout)
quantile(smldat4$Qout)

# QA Facility data
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_2', 'runid_400','runid_600'),
  'metric' = c('wd_mgd', 'wd_mgd', 'wd_mgd'),
  'runlabel' = c('wd_curr', 'wd_tp', 'wd_tpp')
)
fac_data <- om_vahydro_metric_grid( 
  metric = NA, 
  runids = df, 
  bundle = 'facility',ftype = 'all',
  model_version = "vahydro-1.0", ds = ds
)
roa_wddata = fn_extract_basin(fac_data,'OR7_8490_0000')
