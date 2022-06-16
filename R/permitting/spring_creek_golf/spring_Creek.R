library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
# rmarkdown::render('C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', params = list( rseg.hydroid = 68113, fac.hydroid = 73024, runid.list = c("runid_400","runid_600"), intake_stats_runid = 11,upstream_rseg_ids=c(68113) ))
# river
rpid = 4708283
rhid = 68113
relid = 207775 # north anna element
lrelid = 352171 # camp creek local element
# facility
fpid = 4827020
fhid = 73024
felid = 279233
# runoff (for checking)
roelid = 279207

datr11 <- om_get_rundata(relid, 11, site = omsite)
quantile(datr11$Runit)
datr401 <- om_get_rundata(relid, 401, site = omsite)
datr601 <- om_get_rundata(relid, 601, site = omsite)
datr801 <- om_get_rundata(relid, 801, site = omsite)
bccc <- as.data.frame(
  datbc602[,
    c("impoundment_use_remain_mg",
      "impoundment_days_remaining",
      "bc_release_cfs")
  ]
)

datlr401 <- om_get_rundata(lrelid, 401, site = omsite)
datlr601 <- om_get_rundata(lrelid, 601, site = omsite)
dr4 <- as.data.frame(datlr401)
dr6 <- as.data.frame(datlr601)

datf11 <- om_get_rundata(felid, 11, site = omsite)
datf13 <- om_get_rundata(felid, 13, site = omsite)
datf401 <- om_get_rundata(felid, 401, site = omsite)
datf601 <- om_get_rundata(felid, 601, site = omsite)
datf801 <- om_get_rundata(felid, 801, site = omsite)
quantile(datf601$Qreach,probs=c(0,0.01,0.05,0.10, 0.25,0.5))
quantile(datf601$Qintake,probs=c(0,0.01,0.05,0.10, 0.25,0.5))

df6 <- as.data.frame(datf601)
df4 <- as.data.frame(datf401)

quantile(datf401$Qintake)
quantile(datf401$refill_pump_mgd)
quantile(datf401$refill_available_mgd)
quantile(datf601$Qintake)
quantile(datf601$refill_pump_mgd)
quantile(datf601$refill_available_mgd)

rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  output_file = '/WorkSpace/modeling/projects/york_river/south_anna/spring_creek/VWP_summary_spring_creek_v02.docx', 
  params = list( 
    rseg.hydroid = 68113, fac.hydroid = 73024, 
    runid.list = c("runid_400","runid_601"), 
    intake_stats_runid = 400,upstream_rseg_ids=c(68120) 
  )
)

library("openmi.om")

source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
basepath = "/var/www/R"
source("/var/www/R/config.R")
# Create datasource
drupalsite = "http://deq1.bse.vt.edu:81/d.dh"

ds <- RomDataSource$new(drupalsite, 'restws_admin')
ds$get_token(rest_pw)
model_prop <- RomProperty$new(ds,list(featureid = 73024, entity_type = 'dh_feature', propcode = 'vahydro-1.0'), TRUE)
src_json_node <- paste(drupalsite, "node/62", model_prop$pid, sep="/")
load_txt <- ds$auth_read(src_json_node, "text/json", "")

load_objects <- fromJSON(load_txt)
# the objec comes in encapsulated inside of a single json
# object with the name of the object.  This is funky and we may
# consider removing this, since it presupposes that the
# client knows the name of the object before parsing the object.
model_json <- load_objects[[model_prop$propname]]
model <-  openmi_om_load(model_json)
model$init()
model$components$available_mgd$vars
