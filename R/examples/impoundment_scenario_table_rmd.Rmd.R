---
  date: "`r format(Sys.time(), '%m/%d/%Y')`"
author: ""
title: "`r params$doc_title`"
output: 
  officedown::rdocx_document:
  mapstyles:
  Normal: ['First Paragraph']
page_margins:
  bottom: 0.5
top: 0.5
right: 1
left: 0.5
header: 0.0
footer: 0.0
params: 
  doc_title: "VWP CIA Summary - [INSERT PROJECT NAME HERE]"
  image_names: ["fig.imp_storage.all"]
  column_descriptions: ["Storage & Flows"]
  model_features: 
---
  
```{r setup, include=FALSE}

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

model_features <- params$model_features
scenarios <- params$scenarios
model_version <- params$model_version
image_names <- params$image_names
column_descriptions <_ params$column_descriptions

model_pids <- list()
#image_names = c("fig.unmet_heatmap_amt", "fig.imp_storage.all", "fig.monthly_demand")
col_max = 2

for (i in 1:length(model_features)) {
  hid<- model_features[[i]]
  message(i)
  model <- RomProperty$new(ds,list(featureid=hid, propcode=model_version, entity_type='dh_feature'),TRUE)
  model_json = ds$prop_json_cache[model$pid]
  if (is.null(model_json[[1]])) {
    ds$get_json_prop(model$pid) # this stashes it for future use.
  }
  model_pids[[i]] <- model$pid
}

itable = om_multi_image_list(ds, model_pids, scenarios, image_names, column_descriptions)
om_rmd_img_table(itable,2)
