# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("rjson")
library("hydrotools")
library("openmi.om")

source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
basepath = "/var/www/R"
source("/var/www/R/config.R")

fid = 72930 # facility hydro id that houses the models
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token(rest_pw)
source_model <- RomProperty$new(
  ds,
  list(
    featureid = fid,
    entity_type = 'dh_feature',
    propcode = 'vwp-1.0'
  ),
  TRUE
)
src_json_node <- paste(drupalsite, "node/62", source_model$pid, 'single_json', sep="/")
load_txt <- ds$auth_read(src_json_node, "text/json", "")
src_object <- fromJSON(load_txt)

src_object$safeyield_mgd

dest_model <- RomProperty$new(
  ds,
  list(
    featureid = fid,
    entity_type = 'dh_feature',
    propcode = 'vahydro-1.0'
  ),
  TRUE
)
dest_json_node <- paste(drupalsite, "node/62", dest_model$pid, 'single_json', sep="/")
load_txt <- ds$auth_read(dest_json_node, "text/json", "")
dest_object <- fromJSON(load_txt)

# Copy impoundment properties
# this can do all except the impoundment stage/storage table because
# the rest services in hydrotools can't yet save data matrices
for (iprop in c('full_surface_area', 'maxcapacity', 'initstorage')) {
  imp_p1 <- src_object$impoundment[[iprop]]
  imp_p2 <- RomProperty$new(ds,list(pid=dest_object$local_impoundment[[iprop]]$id), TRUE)
  imp_p2$propvalue = imp_p1$value
  imp_p2$save(TRUE)
}

s_p1 <- src_object$drainage_area
s_p2 <- RomProperty$new(ds,list(pid=dest_object$local_area_sqmi$id), TRUE)
s_p2$propcode = s_p1$equation$value
s_p2$save(TRUE)
