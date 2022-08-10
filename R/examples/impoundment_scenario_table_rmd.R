library("hydrotools")
library("openmi.om")
library("jsonlite")
basepath='/var/www/R'
source('/var/www/R/config.R')
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)

# create a table of grouped impoundment images

model_features <- c(68210, 68123, 68183)
model_version <- 'vahydro-1.0'
models <- list()
scenario <- 'runid_400'
img_name <- 'fig.imp_storage.all'
col_max = 2


for (i in 1:length(model_features)) {
  hid<- model_features[[i]]
  #feature <- RomFeature$new(ds,list(hydroid=hid),TRUE)
  message(i)
  feature <- RomFeature$new(ds,list(hydroid=hid),TRUE)
  model <- RomProperty$new(ds,list(featureid=hid, propcode=model_version),TRUE)
  model_obj_url <- paste(json_obj_url, model$pid, sep="/")
  model_info <- om_auth_read(model_obj_url, token,  "text/json", "")
  model <- fromJSON(model_info)
  models[[i]] <- model[[1]]
}

thiscol = 1
thisrow = 1
img_table_markdown = ''
img_matrix <- matrix(NA, ceiling(length(model_features)/col_max),col_max)
for (i in 1:length(models)) {
  model = models[[i]]
  scen_results <- find_name(model, scenario)
  fig_prop <- find_name(scen_results,img_name)
  if (!(is.null(fig_prop))) {
    fig_path <- fig_prop$code
    # we have an image, show it 
    img_markdown <- paste(
      paste0("#### Reservoir Storage: ", model$name),
      paste0("![](",fig_path,")"),
      sep="\n"
    )
    
  } else {
    # tbd: try impoundment linked to river segment.
    img_markdown <- paste("No active impoundment found for",model$name)
  }
  if (thiscol > col_max) {
    thiscol = 1
    thisrow <- thisrow + 1
  }
  img_matrix[thisrow, thiscol] = img_markdown
  thiscol <- thiscol + 1
}