# This function searches for a remote or local name within all broadcasts
# on a given model, and reports back what it has found.
# If multiple are found on same channel, there could be a problem

# feature hydroid
hydroid <- 68137
mversion <- 'vahydro-1.0'
bc_target <- "run_mode" # what write var are we searching for?
target_type <- "remote" # remote
bc_mode <- "cast"
bc_class <- "hydroObject"
bc_hub <- "child"
bc_target = "run_mode"


#install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("rjson")
library("hydrotools")
library("openmi.om")

source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
basepath = "/var/www/R"
source("/var/www/R/config.R")
# Create datasource
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", 'restws_admin')
ds$get_token(rest_pw)


model_prop <- RomProperty$new(ds,list(featureid = hydroid, entity_type = 'dh_feature', propcode = mversion), TRUE)
src_json_node <- paste('http://deq1.bse.vt.edu/d.dh/node/62', model_prop$pid, sep="/")
load_txt <- ds$auth_read(src_json_node, "text/json", "")
load_objects <- fromJSON(load_txt)
model_json <- load_objects[[model_prop$propname]]
model <-  openmi_om_load(model_json)
model$init()

comp_names <- names(model$components)
if (target_type == "local") {
  tid = 1
} else {
  tid = 2
}
found_lines = data.frame (
  "component_name" = character,
  "local" = character,
  "remote" = character
)
k = 0
for (cn in comp_names) {
  model_comp_info = find_name(load_objects, cn)
  if (model_comp_info$object_class == 'broadCastObject') {
    if (
      (model_comp_info$broadcast_mode$value == bc_mode)
      & (model_comp_info$broadcast_hub$value == bc_hub)
      & (model_comp_info$broadcast_class$value == bc_class)
    ) {
      
      bc_lines = model_comp_info$broadcast_params$value
      bc_num <- length(bc_lines)
      for (j in 1:bc_num) {
        bline = bc_lines[[j]]
        if (bline[tid] == bc_target) {
          print("Found")
          k = k + 1
          found_lines <- rbind(
            found_lines,
            list(
              component_name = cn, 
              local = as.matrix(bline)[,1][1], 
              remote = as.matrix(bline)[,1][2]
            )
          )
        }
        
      }
    }
  }
}

if (k > 1) {
  message("Multiple found, this could cause additive errors")
}
print(found_lines)
