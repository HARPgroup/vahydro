# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  output_file = '/usr/local/home/git/vahydro/R/permitting/rivanna/lake_monticello_v01.docx', 
  params = list( 
    rseg.hydroid = 67758, fac.hydroid = 74458, runid.list = c("runid_401","runid_601"), 
    intake_stats_runid = 11 
  )
)


gageid = "02062500"
historic <- dataRetrieval::readNWISdv(gageid,'00060')
historic$month <- month(as.Date(historic$Date))
om_flow_table(historic, "X_00060_00003")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 306466 # Dom Pitts
fdat4 <- om_get_rundata(felid, 401, site=omsite)
quantile(fdat4$Qintake)


smlelid <- 252119
smldat4 <- om_get_rundata(smlelid, 401, site=omsite)
quantile(smldat4$impoundment_Qin)
mean(smldat4$impoundment_Qin)


roelid <- 251269  
rodat4 <- om_get_rundata(roelid, 400, site=omsite)
quantile(rodat4$Runit)
mean(rodat4$impoundment_Qin)


df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export"
)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")


df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_401', 'runid_401', 'runid_401', 'runid_601', 'runid_601', 'runid_601'),
  'metric' = c('Qout', 'l90_Qout', 'wd_mgd', 'Qout', 'wd_mgd','l90_Qout'),
  'runlabel' = c('Qout_400', 'L90_400', 'wd_mgd_400', 'Qout_600', 'wd_mgd_600', 'L90_vwpp')
)
cc_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export"
)

riv_data <- sqldf(
  "select a.*, b.da
   from cc_data as a
  left outer join da_data as b
  on (a.pid = b.pid)
  where hydrocode in (
    'vahydrosw_wshed_OR3_7740_8271',
    'vahydrosw_wshed_OR1_8320_8271',
    'vahydrosw_wshed_OR2_8460_8271'
  )
  order by da
  "
)
riv_data
