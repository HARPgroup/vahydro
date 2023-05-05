library('hydrotools')
library('zoo')
library("IHA")
basepath='/var/www/R';
source("/var/www/R/config.R")
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)


################################################################################################
# LOAD MODEL IDs:
r_elid <- 210901  
fac_elid <- 	218543 # Chesdin WTP
rsvr_elid = 210939 # Lake Chesdin
################################################################################################
################################################################################################

runid <- 400
runid = 601

rdat <- om_get_rundata(r_elid, runid, site = omsite)
pre_storm <- group4(rdat$local_channel_Qin)
post_storm <- group4(rdat$local_channel_Qout)

boxplot(rdat$impoundment_Qin ~ rdat$year)

quantile(rdat$impoundment_use_remain_mg)
quantile(rdat$release_cfs)
quantile(rdat$wd_mgd)
mean(rdat$impoundment_Qin)
mean(rdat$impoundment_Qout)
quantile(rdat$Qreach)
quantile(rdat$wd_cumulative_mgd)
# Facility
facdat <- om_get_rundata(fac_elid, runid, site = omsite)
quantile(facdat$vwp_max_mgd)
quantile(facdat$wd_mgd)
quantile(facdat$flowby)
quantile(facdat$impoundment_use_remain_mg)
quantile(facdat$drought_status)
quantile(facdat$base_demand_pstatus_mgd)

quantile(facdat$unmet_demand_mgd)

kable(om_flow_table(facdat, "refill_pump_mgd"))


br_elid = 213547 # bush river
brdat <- om_get_rundata(br_elid, runid, site = omsite)
quantile(brdat$wd_cumulative_mgd)

us_elid = 212403 # container bush river
usdat <- om_get_rundata(us_elid, runid, site = omsite)
quantile(usdat$wd_upstream_mgd)

ab_elid = 212393 # container bush river
abdat <- om_get_rundata(ab_elid, runid, site = omsite)
quantile(abdat$wd_upstream_mgd)

chesdat <- om_get_rundata(rsvr_elid, runid, site = omsite)
quantile(chesdat$flowby)


# GET DA
df_area <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric = metric, runids = df_area,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
da_data <- sqldf(
  "select pid, propname, riverseg, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")

# GET RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_601', 'runid_400', 'runid_601'),
  'metric' = c('l90_Qout','l90_Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd'),
  'runlabel' = c('L90_perm', 'L90_prop', 'wd_400', 'wd_600')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# Examples of fn_extract_basin
# Appomattox
appomattox_data <- fn_extract_basin(wshed_data,'JA5_7480_0001')

# Three ways to get the list of segments:
# 1. Use the dataframe returned from om_vahydro_metric_grid()
#   - can be useful as it will ONLY get segments that have been modeled for the scenario
#   - can be problematic cause it ONLY gets segments that have been modeled :)
# GET RIVERSEG l90_Qout DATA
conf <- data.frame( model_version ='vahydro-1.0',  runid = 'runid_600', metric='l90_Qout', runlabel='l90_prop')
om_data <- om_vahydro_metric_grid(
  metric = False, runids = conf, 
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
seglist <- data.frame(riverseg = wshed_data$riverseg, propname = wshed_data$propname)
# 2. Use ds$get() call
#    - this is a touch slower, but very concise
seglist <- ds$get('dh_feature', config=list(ftype='vahydro',bundle='watershed'))
# 3. There is also a views public query available which should be super fast

# Then, extract the basin using fn_extract_basin()
app_segs <- fn_extract_basin(seglist, 'JA5_7480_0001')


