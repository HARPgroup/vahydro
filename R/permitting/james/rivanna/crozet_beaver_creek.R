# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 347352
relid <- 351963
roelid <- 351959 

bcdatf4 <- om_get_rundata(felid, 401, site=omsite)

bcdatr4 <- om_get_rundata(relid, 401, site=omsite)

bcdatro4 <- om_get_rundata(roelid, 401, site=omsite)

