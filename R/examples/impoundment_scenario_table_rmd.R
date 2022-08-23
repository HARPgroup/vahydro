library("hydrotools")
library("openmi.om")
library("jsonlite")
library("knitr")
basepath='/var/www/R'
source('/var/www/R/config.R')
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)
ds$json_obj_url <- json_obj_url

# create a table of grouped impoundment images

model_features <- c(68210, 68123, 68183)
model_version <- 'vahydro-1.0'
models <- list()
scenario <- 'runid_400'
img_name <- 'fig.imp_storage.all'
col_max = 2

for (i in 1:length(model_features)) {
  hid<- model_features[[i]]
  message(i)
  model <- RomProperty$new(ds,list(featureid=hid, propcode=model_version),TRUE)
  ds$get_json_prop(model$pid)
  models[[i]] <- model$pid
}

om_scen_element_table <- function(ds,models, scenario, propname, col_max=2) {
  thiscol = 1
  thisrow = 1
  img_table_markdown = ''
  attribute_matrix <- matrix(NA, ceiling(length(models)/col_max),col_max)
  for (i in 1:length(models)) {
    model = ds$prop_json_cache[models[[i]]]
    if (is.null(model[[1]])) {
      # try to retrieve?
      model <- list(name=paste("Unknown Model (note: you must run ds$get_json_prop() to retrieve models before running this function).", models[[i]]))
    }
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
    attribute_matrix[thisrow, thiscol] = img_markdown
    thiscol <- thiscol + 1
  }
  return(attribute_matrix)
}
