# Foundation 4 - model results
# http://deq2.bse.vt.edu/d.dh/entity-model-prop-level/all/dh_feature/watershed/vahydro/vahydro-1.0/runid_13/l90_cc_year 

library("sqldf")
library("stringr") #for str_remove()

# Location of source data
base_url <- "http://deq2.bse.vt.edu/d.dh/entity-model-prop-level-export/all/dh_feature/watershed/vahydro/vahydro-1.0"
runid <- 'runid_13'
metric <- 'l90_Qout'
data_raw <- read.csv(paste(base_url,runid,metric,sep="/"))

dest <- "wsp2020.model.riverseg.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"


