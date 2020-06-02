# Foundation 4 - model results
# http://deq2.bse.vt.edu/d.dh/entity-model-prop-level/all/dh_feature/watershed/vahydro/vahydro-1.0/runid_13/l90_cc_year 

library("sqldf")
library("stringr") #for str_remove()

#----LOAD DATA-------------------------------
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
#folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
#folder <- "C:/Workspace/tmp/"
runids = c(
  'runid_11', 'runid_12', 'runid_13', 'runid_14',
  'runid_15', 'runid_16', 'runid_17', 'runid_18',
  'runid_19', 'runid_20'
)
 
vahydro_foundation4_export <- function (
  alldata,
  metric,
  runid,
  folder,
  save_to_file = TRUE,
  featureid = 'all',
  entity_type = 'dh_feature',
  bundle = 'watershed',
  ftype = 'vahydro',
  model_version = 'vahydro-1.0',
  base_url = "http://deq2.bse.vt.edu/d.dh/entity-model-prop-level-export"
) {
  alldata = NULL
  params <- paste(featureid,entity_type,bundle,ftype,model_version, runid, metric,sep="/")
  url <- paste(base_url,params,sep="/")
  print(paste("retrieving ", url))
  rawdata <- read.csv(url)
  if (is.null(alldata) ) {
    alldata = sqldf(
      paste(
        "select a.pid, a.propname, a.hydrocode, a.featureid, a.attribute_value as ",
        runid, 
        "from rawdata as a "
      )
    )
  } else {
    alldata = sqldf(
      paste(
        "select a.*, b.attribute_value as ",
        runid, 
        "from alldata as a 
      left outer join rawdata as b 
      on (
        a.featureid = b.featureid
        and a.pid = b.pid
      )"
      )
    )
  }
  # Save the metric specific file
  if (save_to_file == TRUE) {
    filename <- paste0(folder,"metrics_", bundle, "_", metric,".csv")
    print(paste0("Writing file: ", filename))
    write.csv(alldata,filename)
  }
  return(alldata)
}

# Watersheds
alldata = NULL
metrics = c('l90_Qout', 'l30_Qout', 'l90_cc_Qout', 'l30_cc_Qout', '7q10', 'ml8', 'wd_cumulative_mgd', 'ps_cumulative_mgd','wd_mgd', 'ps_mgd', 'consumptive_use_frac')
for (metric in metrics) {
  for (runid in runids) {
    alldata <- vahydro_foundation4_export(
      alldata, metric, runid, folder, save_to_file = TRUE
    )
  }
}
wshed_data = alldata

# Facilities
alldata = NULL
metrics <- c('wd_mgd', 'ps_mgd', 'r1_mgd', 'r7_mgd', 'r30_mgd', 'r90_mgd')
for (metric in metrics) {
  for (runid in runids) {
    alldata <- vahydro_foundation4_export(
      alldata, metric, runid, folder, save_to_file = TRUE,
      featureid = 'all', entity_type = 'dh_feature', 
      bundle = 'facility', ftype = 'all'
    )
  }
} 
fac_rseg <- alldata
