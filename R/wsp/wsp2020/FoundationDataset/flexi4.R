vahydro_foundation4_export <- function (
  metric,
  runids,
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
  for (i in 1:nrow(runids)) {
    runinfo = runids[i,]
    if (is.data.frame((runinfo))) {
      print("Found info")
      print(runinfo)
      # user is passing in other params in data frame format
      runid = as.character(runinfo$runid)
      if (!is.null(runinfo$model_version)) model_version = as.character(runinfo$model_version)
      if (!is.null(runinfo$metric)) metric = as.character(runinfo$metric)
      if (!is.null(runinfo$runlabel)) runlabel = as.character(runinfo$runlabel)
    } else {
      # only runid is passed in
      runid = runinfo
      runlabel = runid
    }
    runlabel <- str_replace_all(runlabel, '-', '_')
    runlabel <- str_replace_all(runlabel, ' ', '_')
    params <- paste(featureid,entity_type,bundle,ftype,model_version, runid, metric,sep="/")
    url <- paste(base_url,params,sep="/")
    print(paste("retrieving ", url))
    rawdata <- read.csv(url)
    if (is.null(alldata) ) {
      alldata = sqldf(
        paste(
          "select a.pid, a.propname, a.hydrocode, a.featureid, a.riverseg, a.attribute_value as ",
          runlabel, 
          "from rawdata as a "
        )
      )
    } else {
      mergeq = paste(
        "select a.*, b.attribute_value as ",
        runlabel, 
        "from alldata as a 
        left outer join rawdata as b 
        on (
          a.featureid = b.featureid
        )"
      )
      message(mergeq)
      alldata = sqldf(
        mergeq
      )
    }
  }
  # Save the metric specific file
  if (save_to_file == TRUE) {
    filename <- paste0(folder,"metrics_", bundle, "_", metric,".csv")
    write.csv(alldata,filename)
  }
  return(alldata)
}


df <- data.frame(
  'model_version' = c('usgs-1.0',  'CFBASE30Y20180615', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11', 'runid_1151', 'runid_1153'),
  'runlabel' = c('USGS', 'CBP6', 'VAH Daily', 'VAH 6 hr', 'VAH 3 hr'),
  'metric' = c('90 Day Min Low Flow','90 Day Min Low Flow','l90_Qout','l90_Qout','l90_Qout')
)
# choose one to test
#df <- as.data.frame(df[3,])

wshed_data <- vahydro_foundation4_export(metric, df, folder, save_to_file = TRUE)
