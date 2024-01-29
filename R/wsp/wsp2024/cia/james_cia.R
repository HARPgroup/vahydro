options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0','vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_400', 'runid_600', 'runid_400', 'runid_600'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','l30_Qout', 'l30_Qout'),
  'runlabel' = c('Qout_400', 'Qout_600', 'wd_400', 'wd_600', 'l30_400', 'l30_600')
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
jar_data6 = fn_extract_basin(wshed_data6,'JL7_7070_0001')

# Get Runoff Data for QA
rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_600', 'runid_800'),
  'metric' = c('Runit','Runit'),
  'runlabel' = c('Runit_perm', 'Runit_800')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
jar_rodata = fn_extract_basin(ro_data,'JL7_7070_0001')
fn_upstream('JL7_7070_0001', seglist)
fn_upstream('JL7_7070_0001', wshed_data$riverseg)


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


# get Jackson
rdat_jack400 <- om_get_rundata(214595, 400, site=omsite)
rdat_jack401 <- om_get_rundata(214595, 401, site=omsite)
j6950_df401 <- as.data.frame(rdat_jack401)
j6950_df400 <- as.data.frame(rdat_jack400)
cmp6950 <- sqldf(
  "select a.year, a.month, a.day, a.Qup, b.Qup as Qup_400, 
   a.Qout, b.Qout as Qout_400, 
   a.wd_mgd, b.wd_mgd as wd_mgd_400,
   a.ps_mgd, b.ps_mgd as ps_mgd_400
  from j6950_df401 as a 
  left outer join j6950_df400 as b 
  on (a.year = b.year and a.month = b.month and a.day = b.day)
  order by a.year, a.month, a.day
  "
)
quantile(cmp6950$Qout_400)
quantile(cmp6950$Qout)

jacK_6950 <- om_quantile_table(as.data.frame(rdat_jack401), metrics = c(
  "Qup","Qout","wd_mgd","wd_cumulative_mgd",
  "ps_mgd","ps_cumulative_mgd"
),
rdigits = 2
)
kable(jacK_6950,'markdown')

rdat_jack7330_400 <- om_get_rundata(213253, 400, site=omsite)
rdat_jack7330_401 <- om_get_rundata(213253, 401, site=omsite)
j7330_df401 <- as.data.frame(rdat_jack7330_401)
j7330_df400 <- as.data.frame(rdat_jack7330_400)
cmp7330 <- sqldf(
  "select a.year, a.month, a.day, a.Qup, b.Qup as Qup_400, 
   a.Qout, b.Qout as Qout_400, 
   a.wd_mgd, b.wd_mgd as wd_mgd_400,
   a.ps_mgd, b.ps_mgd as ps_mgd_400
  from j7330_df401 as a 
  left outer join j7330_df400 as b 
  on (a.year = b.year and a.month = b.month and a.day = b.day)
  order by a.year, a.month, a.day
  "
)

jacK_7330 <- om_quantile_table(as.data.frame(rdat_jack7330_401), metrics = c(
  "Qup","Qout","wd_mgd","wd_cumulative_mgd",
  "ps_mgd","ps_cumulative_mgd"
),
rdigits = 2
)
kable(jacK_7330,'markdown')


chan_jack_6950 <- om_get_rundata(213289, 400, site=omsite)


# Baseline
# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_0', 'runid_600'),
  'metric' = c('Qout','Qout'),
  'runlabel' = c('Qout_0', 'Qout_600')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

jb_data <- sqldf("select * from wshed_data where riverseg like 'JB%'")
