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
quantile(facdat$drought_status_local, probs=c(0.5,0.7,0.7,0.9,0.95,1.0))
quantile(facdat$day)
quantile(facdat$flowby)

# verify remaining calcs
quantile(facdat$impoundment_use_remain_mg,probs=c(0,0.02,0.05,0.1,0.2))
quantile(chesdat$use_remain_mg,probs=c(0,0.02,0.05,0.1,0.2))
quantile( (chesdat$Storage - 466.7)/3.07/chesdat$child_wd_mgd)
quantile(facdat$impoundment_use_remain_mg,probs=c(0,0.02,0.05,0.1,0.2))

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
chesdat1 <- as.data.frame(om_get_rundata(rsvr_elid, 11, site = omsite))
chesdat4 <- as.data.frame(om_get_rundata(rsvr_elid, 401, site = omsite))
chesdat1$runid <- 11
chesdat4$runid <- 400
quantile(chesdat4$release)
quantile(chesdat$Qin)
quantile(chesdat$Qout)
quantile(chesdat$evap_mgd)
quantile(chesdat$use_remain_mg)

ches_cols = c('runid', 'year', 'month', 'day', 'Qin', 'Qout', 'spill', 'release', 'simple_flowby', 'tiered_flowby', 'Qmax', 'use_remain_mg', 'demand')
ches_cols = c('runid', 'year', 'month', 'day', 'Qin', 'Qout', 'release', 'simple_flowby', 'tiered_flowby', 'Qmax', 'use_remain_mg', 'demand')

dry_4 <- chesdat4[,ches_cols]
dry_1 <- chesdat1[,ches_cols]
chesrundat <- sqldf(
  "select * from (
    select * from dry_1 
    UNION 
    select * from dry_4
  ) 
  where year = 2002
  and month = 7
  and day in (1,2,3)
  order by year, month, day
  "
)

rbind(dry_1[,ches_cols], dry_4[,ches_cols])

quantile(chesdat$Qin / 1.547 - chesdat$evap_mgd - chesdat$Qout / 1.547 - chesdat$demand )
mean(chesdat$Qin) - mean(chesdat$Qout)
mean(chesdat$demand)

# make sure the reecharge object is not zero!  if so, big problem...
quantile(chesdat$R25_r_q)
quantile(chesdat$Qmax)

# now that everyting is good, run the CIA stats
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
  'model_version' = c( 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_6001'),
  'metric' = c('wd_cumulative_mgd', 'wd_cumulative_mgd', 'wd_cumulative_mgd'),
  'runlabel' = c('wd_400', 'wd_600', 'wd_6001')
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
conf <- data.frame( model_version ='vahydro-1.0',  runid = 'runid_400', metric='wd_cumulative_mgd', runlabel='Cumu WD')
om_data <- om_vahydro_metric_grid(
  metric = False, runids = conf, 
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
seglist <- data.frame(riverseg = wshed_data$riverseg, propname = wshed_data$propname)
# 2. Use ds$get() call
#    - this is a touch slower, but very concise
seglist <- ds$get('dh_feature', config=list(ftype='vahydro',bundle='watershed'))
seglist$riverseg <- str_replace(seglist$hydrocode, 'vahydrosw_wshed_', '')
# 3. There is also a views public query available which should be super fast

# Then, extract the basin using fn_extract_basin()
app_data <- fn_extract_basin(om_data, 'JA5_7480_0001')
app_segs <- fn_extract_basin(seglist, 'JA5_7480_0001')
app_map <- model_geoprocessor(app_segs)

model_geoprocessor <- function(seg_features) {
  for (i in 1:nrow(seg_features)) {
    spone <- sp::SpatialPolygonsDataFrame(
      readWKT(seg_features[i,]$dh_geofield), 
      data=as.data.frame(as.list(subset(seg_features[i,],select=-c(dh_geofield))))
    )
    if (i == 1) {
      # start with one 
      polygons_sp <- spone
    } else {
      # append
      polygons_sp <- rbind(polygons_sp, spone)
    }
  }
  return(polygons_sp)
}
