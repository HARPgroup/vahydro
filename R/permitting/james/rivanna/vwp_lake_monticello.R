# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 340406
fccelid <- 353085 # Fluvanna Women's Correctional
relid <- 337730
welid <- 340400 # withdrawal container
roelid <- 352048 

runid = 601
datfcc <- om_get_rundata(fccelid, runid, site=omsite)
quantile(datfcc$Runit)
quantile(datfcc$wd_mgd)
quantile(datfcc$ps_mgd)
quantile(datfcc$discharge_mgd)
quantile(datfcc$available_mgd)
quantile(datfcc$local_impoundment_use_remain_mg)
quantile(datfcc$local_impoundment_max_usable)
quantile(datfcc$Qintake)
quantile(datfcc$flowby)
quantile(datfcc$refill_pump_mgd)

datf4 <- om_get_rundata(felid, 400, site=omsite)
datf6 <- om_get_rundata(felid, 600, site=omsite)
datwd <- om_get_rundata(351973, 601, site=omsite) 
quantile(datwd$wd_mgd)
om_flow_table(datwd,"wd_mgd")

datr6 <- om_get_rundata(relid, 601, site=omsite)
quantile(datr6$Qout, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datr6$Qnatural, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datr6$ps_cumulative_mgd, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datr6$wd_mgd, probs=c(0,0.01,0.1,0.25,0.5))

dfdatr6 <- as.data.frame(datr6)
rdeets <- sqldf("select * from dfdatr6 where ps_cumulative_mgd < 1.0")
r2019 <- sqldf("select * from dfdatr6 where year = 2019")
datsfr6 <- om_get_rundata(352054, 601, site=omsite)
quantile(datsfr6$tiered_release)
quantile(datsfr6$Q30)
quantile(datsfr6$system_storage_bg)
quantile(datsfr6$system_demand_mgd)
quantile(datsfr6$pct_sys_storage)
quantile(datsfr6$child_wd_mgd)
quantile(datsfr6$drought_status, na.rm = TRUE)


datr4 <- om_get_rundata(relid, 400, site=omsite)

datw4 <- om_get_rundata(welid, 401, site=omsite)

datro4 <- om_get_rundata(roelid, 401, site=omsite)

quantile(datf4$available_mgd)
quantile(datf6$available_mgd, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datf6$flowby, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datf6$Qintake, probs=c(0,0.01,0.1,0.25,0.5))
quantile(datf6$unmet_demand_mgd, probs=c(0.25,0.5,0.75,0.999))
max(datf6$unmet_demand_mgd)

quantile(datr6$Qout, probs=c(0,0.01,0.1,0.25,0.5))

rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  output_file = '/usr/local/home/git/vahydro/R/permitting/rivanna/lake_monticello_v05.docx', 
  params = list( 
    rseg.hydroid = 68137, fac.hydroid = 72634, 
    runid.list = c("runid_400","runid_600"), 
    intake_stats_runid = 600,
    upstream_rseg_ids=c(68183, 68123, 68309) 
  )
)

# USGS gage analysis
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/rivanna/JL4_6520_6710_02034000.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 337730,
    runid = 200,
    gageid = '02034000'
  )
)
