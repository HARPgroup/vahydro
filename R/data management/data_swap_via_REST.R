#ISSUE QUEUE https://gitlab.deq.virginia.gov/VAHydro/VAHydro/-/issues/79 - GW0002201 Woods Edge DATA SWAP
library("hydrotools")
library('sqldf')
library("zoo")
library('httr')
options(scipen = 999)
# SPECIFY THE DRUPAL DEVELOPMENT SITE: d.dh, d.alpha, d.bet
dev_site <- "d.bet"

ds1 <- RomDataSource$new(paste0("http://deq1.bse.vt.edu/",dev_site,"/"), "restws_admin")
ds1$get_token()

feat_1092 <- RomFeature$new(ds1,list(hydroid=1092),TRUE)
#SAVE ALL TIMESERIES FOR THIS FEATURE
tsv_feat_1092 <- feat_1092$tsvalues()
sqldf('SELECT varid, count(*)
      from tsv_feat_1092
      group by varid')

write.csv(tsv_feat_1092, paste0("C:/Users/maf95834/Documents/feature_ts_1092_",dev_site,".csv"))

#all ts between July 2012 and December 2020
stime <- as.numeric(as.POSIXct("2012-07-01"))
etime <- as.numeric(as.POSIXct("2020-12-31"))
tsv_1092 <- sqldf(paste0('SELECT *
                 FROM tsv_feat_1092
                 WHERE tstime <=', etime,' 
                 AND tstime >= ',stime,'
                 ORDER BY tstime ASC'))

# #QA CHECK - wlg variable between July 2012 and December 2018
# tsv <- feat_1092$tsvalues(varkey='wlg')
# stime <- as.numeric(as.POSIXct("2012-07-01"))
# etime <- as.numeric(as.POSIXct("2018-12-31"))
# tsv_wlg_1092 <- sqldf(paste0('SELECT *
#                  FROM tsv
#                  WHERE tstime <=', etime,' 
#                  AND tstime >= ',stime,''))
# 
# 
# #QA CHECK - meter reading variable between January 2019 and December 2020
# names(tsv)
# tsv <- feat_1092$tsvalues(varkey='wd_meter_reading')
# stime <- as.numeric(as.POSIXct("2019-01-01"))
# etime <- as.numeric(as.POSIXct("2020-12-31"))
# tsv_wdmeterreading_1092 <- sqldf(paste0('SELECT *
#                  FROM tsv
#                  WHERE tstime <=', etime,' 
#                  AND tstime >= ',stime,''))

##################################################################################

feat_1096 <- RomFeature$new(ds1,list(hydroid=1096),TRUE)
#SAVE ALL TIMESERIES FOR THIS feat_1096URE
tsv_feat_1096 <- feat_1096$tsvalues()
sqldf('SELECT varid, count(*)
      from tsv_feat_1096
      group by varid')
write.csv(tsv_feat_1096, paste0("C:/Users/maf95834/Documents/feature_ts_1096_",dev_site,".csv"))

#all ts between July 2012 and December 2020
stime <- as.numeric(as.POSIXct("2012-07-01"))
etime <- as.numeric(as.POSIXct("2020-12-31"))
tsv_1096 <- sqldf(paste0('SELECT *
                 FROM tsv_feat_1096
                 WHERE tstime <=', etime,' 
                 AND tstime >= ',stime,'
                 ORDER BY tstime ASC'))

# #QA CHECK - wlg variable between July 2012 and December 2018
# tsv <- feat_1096$tsvalues(varkey='wlg')
# stime <- as.numeric(as.POSIXct("2012-07-01"))
# etime <- as.numeric(as.POSIXct("2018-12-31"))
# tsv_wlg_1096 <- sqldf(paste0('SELECT *
#                  FROM tsv
#                  WHERE tstime <=', etime,' 
#                  AND tstime >= ',stime,''))
# 
# #QA CHECK - meter reading variable between January 2019 and December 2020
# names(tsv)
# tsv <- feat_1096$tsvalues(varkey='wd_meter_reading')
# stime <- as.numeric(as.POSIXct("2019-01-01"))
# etime <- as.numeric(as.POSIXct("2020-12-31"))
# tsv_wdmeterreading_1096 <- sqldf(paste0('SELECT *
#                  FROM tsv
#                  WHERE tstime <=', etime,' 
#                  AND tstime >= ',stime,''))
sqldf('SELECT varid, count(*)
      from tsv_1092
      group by varid')
sqldf('SELECT varid, count(*)
      from tsv_1096
      group by varid')
##################################################################################
#AFTER PULLING DATA FROM **BOTH** FEATURES 

# Hydroid # of the feature that is being updated (TO this feature)
hid2 <- 1096
# TS dataframe of the data being transferred (FROM this feature)
ts1 <- tsv_1092
for (i in 1:nrow(ts1)) {
  tsrow <- ts1[i,]
  tsl <- as.list(tsrow)
  #NOTE: because the tids exist under one of the features already, when the featureid is switched, the data will *disappear* from the source feature
  #tsl$tid = NULL  #commented out to keep the existing tid
  #tsl$featureid = hid2
  t2 <- RomTS$new(ds1, tsl)
  t2$featureid = hid2 
  t2$save(TRUE)
}

#VERIFY NEW FEATUREID
#returns timeseries object
#tcheck <- RomTS$new(ds1,list(tid=758297),TRUE)
#returns list for that tid
ds1$get_ts(list(tid=t2$tid), return_type = 'data.frame', force_refresh = TRUE)


hid2 <- 1092
ts1 <- tsv_1096
for (i in 1:nrow(ts1)) {
  tsrow <- ts1[i,]
  tsl <- as.list(tsrow)
  #NOTE: because the tids exist under one of the features already, when the featureid is switched, the data will *disappear* from the source feature
  tsl$tid = NULL  #INTENTIONALLY UNcommented - cannot supply a tid that does not exist - system needs to determine its own tid 
  #tsl$featureid = hid2
  t2 <- RomTS$new(ds1, tsl)
  t2$featureid = hid2 
  t2$save(TRUE)
}


##############################################################################
#THE CASE OF THE EXISTING WD_MGM (WITH NO WLG EQUIVALENT)
#best approach would be to write a function that accepts a hydroid, startdate - case by case basis
wlg_list <- wd_mgm
wd_list$tid = NULL
wd_list$varid = ds1$get_vardef('wlg')
wd_ts <- RomTS$new(ds1, wd_list)
wd_ts$tsvalue <- wd_ts$tsvalue * 1000000.0
wd_ts$save(TRUE)
