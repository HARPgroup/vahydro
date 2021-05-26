library("hydrotools")
site = 'http://deq2.bse.vt.edu/d.dh'
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token()

gage_feature <- ds$get(
  'dh_feature', 'hydroid', 
  list(hydrocode = 'usgs_01654000', bundle = 'usgsgage')
)

mllr_prop <- fn_get_rest(
  'dh_properties', 'featureid', 
  list(hydroid = gage_feature->hydroid)
)


col2 <- data.frame(ecols,unlist(entity_cont$list[[i]])[ecols])
names(col2) <- c('colname', 'colval')

df2 <- data.frame(t(col2$colval)
names(df2) <- col2$colname


inputs = list(hydrocode = 'usgs_01654000', bundle = 'usgsgage')


tsf <- RomTS$new(
  ds,
  list( 
    "featureid" = gageinfo$hydroid, 
    "entity_type" = 'dh_feature', 
    "varid" = varids[z], 
    "tstime" =  as.numeric(as.POSIXct(paste(paste(2021, "-03-01", sep=""),"EST"))), 
    "tsvalue" = P_est
  )
)
tsf$save(TRUE)
tsf$save()
inputs = tsf$to_list()
fn_post_rest('dh_timeseries', 'tid', inputs, site, token)

tsl <- tsf$to_list()
fn_search_tsvalues(tsl, ds$tsvalues)
tsl

if (nrow(ds$tsvalues) > 0) {
  ds$tsvalues <- rbind(ds$tsvalues, as.data.frame(ts))
} else {
  ds$tsvalues <- rbind(ts[names(ds$tsvalues)])
}


# For testing timseries object
config = list( 
  "featureid" = gageinfo$hydroid, 
  "entity_type" = 'dh_feature', 
  "varid" = varids[z], 
  "tstime" =  as.numeric(as.POSIXct(paste(paste(calyear, "-03-01", sep=""),"EST"))), 
  "tsvalue" = P_est, 
  "tscode" = P_est
)


datasource <- ds
ds$get_ts(config, 'object')
fn_get_timeseries(config,site, token)
ds$get_ts(config, 'object', TRUE)

config = list( 
  "featureid" = gageinfo$hydroid, 
  "entity_type" = 'dh_feature', 
  "varid" = varids[z], 
  "tstime" =  as.numeric(as.POSIXct(paste(paste(calyear, "-03-01", sep=""),"EST"))), 
  "tsvalue" = P_est, 
  "tscode" = P_est
)
ts <- RomTS$new(
  ds,
  config,
  FALSE
)

ts <- RomTS$new(
  ds,
  config,
  TRUE
)
fn_get_timeseries(config, site, token)
ts$save()
ts$save(TRUE)
ds$tsvalues


# testung data source get_ts()
return_type = 'object'
force_refresh = TRUE
tsvalues <- fn_search_tsvalues(config, ds$tsvalues)
tsvalues <- fn_search_tsvalues(config_list, ds$tsvalues)

tester <- ds$get_ts(config_list, 'object', TRUE)

tsvalues_tmp <- as.data.frame(ds$tsvalues)
sqldf("
  select * from tsvalues_tmp where    
  featureid = 58585 AND entity_type = 'dh_feature' 
  AND varid = '59' AND tstime = '1614574800' 
  AND tsvalue = 0.0270152522084002 
  AND tscode = '0.0270152522084002'
")


pconfig = list( 
  "featureid" = gageinfo$hydroid, 
  "entity_type" = 'dh_feature', 
  "propname" = 'mllr_beta1_july_50'
)

pf <- RomProperty$new(
  ds,
  pconfig,
  TRUE
)
pf$propcode = ''
pl = pf$to_list()
as.integer(as.character(pl[['pid']]))
pf$save(TRUE)

ds$get_prop(pconfig, 'list', TRUE)
ppp <- fn_get_rest('dh_properties', 'pid', pconfig, site, token)
fn_search_properties(pconfig, ds$props)

fn_search_tsvalues(pconfig, ds$props)
