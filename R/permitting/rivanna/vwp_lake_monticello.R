# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 340406
relid <- 337730
welid <- 340400 # withdrawal container
roelid <- 352048 

datf4 <- om_get_rundata(felid, 400, site=omsite)
datf6 <- om_get_rundata(felid, 600, site=omsite)

datr6 <- om_get_rundata(relid, 600, site=omsite)
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
  output_file = '/usr/local/home/git/vahydro/R/permitting/rivanna/lake_monticello_v04.docx', 
  params = list( 
    rseg.hydroid = 68137, fac.hydroid = 72634, 
    runid.list = c("runid_200", "runid_400","runid_600","runid_6001"), 
    intake_stats_runid = 600,
    upstream_rseg_ids=c(68183, 68123, 68309) 
  )
)
