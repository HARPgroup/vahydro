options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

hc_cid <- 326976 
hc_elid <- 326970 # 
ro_omid <- 213265 
runid = 0
hcdat <- om_get_rundata(hc_elid, runid, site=omsite)
hccdat <- om_get_rundata(hc_cid, runid, site=omsite)
