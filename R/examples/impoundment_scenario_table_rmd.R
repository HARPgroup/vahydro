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

om_multi_image_list <- function(ds,model_pids, scenarios, image_names, column_descriptions = c(), label_prefix = "Image") {
  # gets the same image name from multiple models in a single scenario
  # puts into list format compatible with the fn om_rmd_img_table()
  thiscol = 1
  thisrow = 1
  img_list = list() 
  n = 1
  for (i in 1:length(image_names)) {
    img_name = image_names[i]
    if (i > length(column_descriptions)) {
      img_desc = ""
    } else {
      img_desc = column_descriptions[i]
    }
    for (s in 1:length(scenarios)) {
      scenario = scenarios[s]
      for (m in 1:length(model_pids)) {
        model = ds$prop_json_cache[model_pids[[m]]]
        if (is.null(model[[1]])) {
          # try to retrieve?
          model <- list(name=paste("Unknown Model (note: you must run ds$get_json_prop() to retrieve models before running this function).", model_pids[[i]]))
        } else {
          model = model[[1]]
        }
        scen_results <- find_name(model, scenario)
        fig_prop <- find_name(scen_results,img_name)
        img_list[[n]] = list()
        img_list[[n]]$text = paste(img_desc, model$name)
        img_list[[n]]$label = label_prefix
        if (!(is.null(fig_prop))) {
          fig_path <- fig_prop$code
          # we have an image, show it 
          img_list[[n]]$img_url = fig_path
          
        } else {
          # tbd: try impoundment linked to river segment.
          img_list[[n]]$text = paste("No property found for",model$name)
        }
        n = n + 1 # increment image counter
      }
    }
  }
  return(img_list)
}

om_rmd_img_table <- function(image_info, col_max=2, num_prefix="", num_delim=".") {
  thiscol = 1
  thisrow = 1
  if (num_prefix == "") {
    num_delim = ""
  }
  img_pct = round(100 / col_max)
  attribute_matrix <- matrix(NA, ceiling(length(image_info)/col_max),col_max)
  for (i in 1:length(image_info)) {
    this_info = image_info[[i]]
    image_path = this_info$img_url
    # sizing images in Rmd: https://bookdown.org/yihui/rmarkdown-cookbook/figure-size.html
    img_markdown <- paste(
      paste0("**", this_info$label, " ", paste0(num_prefix,num_delim,i), ":** ", this_info$text),
      paste0("![](",image_path,")","{width=",img_pct,"%}"),
      sep="\n"
    )
    if (thiscol > col_max) {
      thiscol = 1
      thisrow <- thisrow + 1
    }
    attribute_matrix[thisrow, thiscol] = img_markdown
    thiscol <- thiscol + 1
  }
  return(attribute_matrix)
}


itable = om_multi_image_list(ds, model_pids, scenarios, image_names, column_descriptions)
om_rmd_img_table(itable,2)
