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
cr_elid = 353091 # Crewe river
crfac_elid = 338920 # Crewe WTP
r_elid <- 245105 
ro_elid <- 245125 # 353007
fac_elid <- 339022

runid <- 401

crdat <- om_get_rundata(cr_elid, runid, site = omsite)
rdat <- om_get_rundata(r_elid, runid, site = omsite)
rodat <- om_get_rundata(ro_elid, runid, site = omsite)

kable(om_flow_table(rdat, "wd_cumulative_mgd"))
kable(om_flow_table(rdat, "wd_upstream_mgd"))
kable(om_flow_table(rdat, "wd_mgd"))

crfacdat <- om_get_rundata(crfac_elid, runid, site = omsite)

facdat <- om_get_rundata(fac_elid, runid, site = omsite)
quantile(facdat$local_impoundment_Qout)
quantile(facdat$wd_mgd)
quantile(facdat$refill_pump_mgd)

#fcols = c('local_impoundment_Storage', 'local_impoundment_Qin', 'local_impoundment_refill_full_mgd', 'local_impoundment_demand', 'local_impoundment_refill')
fcols = c('local_impoundment_Storage', 'local_impoundment_Qin', 'local_impoundment_refill_full_mgd', 'local_impoundment_demand')
detail_dat <- facdat[,fcols]
names(detail_dat) <- c('S', 'Qin', 'need_mgd', 'demand_mgd')
#names(detail_dat) <- c('S', 'Qin', 'need_mgd', 'demand_mgd', 'refill_mgd')
quantile(facdat$local_impoundment_refill_full_mgd)

gc_elid <- 339146 # Greensville County, vwp 13-0957, insure no water conflict
gcdat <- om_get_rundata(gc_elid, runid, site = omsite)
kable(om_flow_table(gcdat, "available_mgd"))
quantile(gcdat$Qintake/1.547)
quantile(gcdat$refill_available_mgd)
quantile( (gcdat$Qintake - gcdat$simple_flowby)/1.547)
quantile( (gcdat$Qintake - gcdat$flowby)/1.547)


# Get all vahydro watersheds
seglist <- ds$get('dh_feature', config=list(ftype='vahydro',bundle='watershed'))
seglist$riverseg <- str_replace(seglist$hydrocode, 'vahydrosw_wshed_', '')
# Then, extract the basin using fn_extract_basin()
app_segs <- fn_extract_basin(seglist, 'MN3_7930_8010')

# Now get watershed users
runid.list = c("runid_400","runid_600")
df = data.frame(runid=runid.list)
df$model_version <- 'vahydro-1.0'
df$metric <- 'wd_mgd'
df$runlabel <- paste('WD MGD', df$runid)

fac_data <- om_vahydro_metric_grid( 
  metric=FALSE, runids=df, featureid='all', 
  entity_type='dh_feature', bundle='facility',
  ftype='all', model_version = 'vahydro-1.0',
  base_url = "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export",
  ds = ds
)
fac_case <- sqldf(
  "select a.* from fac_data as a
   left outer join app_segs as b
   on (a.riverseg = b.riverseg)
  where b.riverseg is not null 
  "
)
# filter out WSP entries (optional)
fac_case <- sqldf("select * from fac_case where hydrocode not like 'wsp_%'")
