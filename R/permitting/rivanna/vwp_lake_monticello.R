# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 340406
relid <- 337730
welid <- 340400 # withdrawal container
roelid <- 352048 

datf4 <- om_get_rundata(felid, 400, site=omsite)
datf6 <- om_get_rundata(felid, 601, site=omsite)

datr4 <- om_get_rundata(relid, 401, site=omsite)

datw4 <- om_get_rundata(welid, 401, site=omsite)

datro4 <- om_get_rundata(roelid, 401, site=omsite)

quantile(datf4$available_mgd)
quantile(datf6$available_mgd)
