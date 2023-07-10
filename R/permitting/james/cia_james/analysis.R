library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_400', 'runid_600', 'runid_11'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','Qout'),
  'runlabel' = c('Qout_perm', 'Qout_prop', 'wdc_400', 'wdc_600', 'Qout_wsp2020')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

jar_data = fn_extract_basin(wshed_data,'JL7_7070_0001')

# Get cbp-6.0 data for water balance comparison

# GET RIVERSEG l90_Qout DATA
df6 <- data.frame(
  'model_version' = c('cbp-6.1',  'cbp-6.1'),
  'runid' = c('subsheds', 'subsheds'),
  'metric' = c('Qout','wd_cumulative_mgd'),
  'runlabel' = c('Qout_cbp6', 'wd_cbp6')
)
wshed_data6 <- om_vahydro_metric_grid(
  metric = metric, runids = df6,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

rockid <- 213049 
romid <- 214907 # james river 7000
ro_omid <- 213265 

rockdat6 <- om_get_rundata(rockid, 600, site=omsite)

rdat4 <- om_get_rundata(romid, 400, site=omsite)
rdat6 <- om_get_rundata(romid, 600, site=omsite)
mean(rdat4$Qout)
mean(rdat6$Qout)

rodat4 <- om_get_rundata(ro_omid, 400, site=omsite)
rodat6 <- om_get_rundata(ro_omid, 600, site=omsite)

quantile(rodat4$Runit)
quantile(rodat6$Runit)

# analyze channel into Lake Moomaw
comid = 213671  # Moomaw inflow River Channel
cdat4 <- om_get_rundata(comid, 400, site=omsite)
cdat6 <- om_get_rundata(comid, 600, site=omsite)
# discrepancy n Qup is large. almost precisely equal to Back Creek trib missing
mean(cdat4$Qup)
mean(cdat6$Qup)
# the aggregator of upstream flows
agid = 213645
agdat4 <- om_get_rundata(agid, 400, site=omsite)
agdat6 <- om_get_rundata(agid, 600, site=omsite)
mean(agdat4$Qup)
mean(agdat6$Qup)
# back creek model flow
bcid = 211743 
bcdat4 <- om_get_rundata(bcid, 400, site=omsite)
bcdat6 <- om_get_rundata(bcid, 600, site=omsite)
mean(bcdat4$Qup)
mean(bcdat6$Qup)

jrup_id = 210493 # James Upstream container

rdat_jrup4 <- om_get_rundata(jrup_id, 400, site=omsite)
rdat_jrup6 <- om_get_rundata(jrup_id, 600, site=omsite)

quantile(rdat_jrup4$Qup)
quantile(rdat_jrup6$Qup)
mean(rdat_jrup4$Qout)
mean(rdat_jrup6$Qout)


quantile(rdat4$Qup)
quantile(rdat6$Qup)
mean(rdat4$Qup)
mean(rdat6$Qup)


