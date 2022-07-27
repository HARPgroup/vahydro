# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 347380 
ielid <- 231301
wselid <- 231299 

lmdatf4 <- om_get_rundata(felid, 401, site=omsite)

lmdati4 <- om_get_rundata(ielid, 401, site=omsite)

lmdat4 <- om_get_rundata(wselid, 401, site=omsite)

