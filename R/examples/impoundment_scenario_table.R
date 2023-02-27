library("hydrotools")
library("openmi.om")
library("jsonlite")
library("knitr")
# load remote code
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/rmd_utils.R")

basepath='/var/www/R'
source('/var/www/R/config.R')
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)
ds$json_obj_url <- json_obj_url

# create a table of grouped impoundment images

#model_features <- c(68210, 68123, 68183)
model_features <- c(456224)
model_version <- 'vahydro-1.0'
model_pids <- list()
scenarios <- c('runid_400')
image_names = c("fig.unmet_heatmap_amt", "fig.imp_storage.all", "fig.monthly_demand")
column_descriptions = c("Unmet Demand", "Storage by Year", "Monthly Demand")
col_max = 2

for (i in 1:length(model_features)) {
  hid<- model_features[[i]]
  message(i)
  model <- RomProperty$new(ds,list(featureid=hid, propcode=model_version),TRUE)
  ds$get_json_prop(model$pid)
  model_pids[[i]] <- model$pid
}

itable = om_multi_image_list(ds, model_pids, scenarios, image_names, column_descriptions)
om_rmd_img_table(itable,2)
