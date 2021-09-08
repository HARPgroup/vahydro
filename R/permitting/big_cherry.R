library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
# river
pid = 5831933
elid = 352078
runid = 6011

# facility
pid = 4826467
elid = 247415
runid = 6014


datbc201 <- om_get_rundata(352078, 201, site = omsite)
datbc301 <- om_get_rundata(352078, 301, site = omsite)
datbc4011 <- om_get_rundata(352078, 4011, site = omsite)
datbc401 <- om_get_rundata(352078, 401, site = omsite)
datbc601 <- om_get_rundata(352078, 601, site = omsite)
datbc6011 <- om_get_rundata(352078, 6011, site = omsite)
datbc6014 <- om_get_rundata(352078, 6014, site = omsite)

datbcfac4011 <- om_get_rundata(247415, 4011, site = omsite)
datbcfac201 <- om_get_rundata(247415, 201, site = omsite)
datbcfac301 <- om_get_rundata(247415, 301, site = omsite)
datbcfac401 <- om_get_rundata(247415, 401, site = omsite)
datbcfac6011 <- om_get_rundata(247415, 6011, site = omsite)
datbcfac6014 <- om_get_rundata(247415, 6014, site = omsite)

ro6014 <- om_get_rundata(247387,  6014, site = omsite)
ro601 <- om_get_rundata(247387,  601, site = omsite)

247387

datbc[200:250,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

datdf <- as.data.frame(datbcfac4011)
modat <- sqldf("select month, avg(base_demand_mgd) as base_demand_mgd from datdf group by month")


# do elfgen manbually
library('elfgen')
runid = 4011
hydroid = 477140
huc_level <- 'huc8'
dataset <- 'VAHydro-EDAS'
scen.propname<-paste0('runid_', runid)
pid = 6540930

ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
# GETTING SCENARIO PROPERTY FROM VA HYDRO
sceninfo <- list(
  varkey = 'om_scenario',
  propname = scen.propname,
  featureid = pid,
  entity_type = "dh_properties",
  bundle = "dh_properties"
)
scenprop <- RomProperty$new( ds, sceninfo, TRUE)

elfgen_huc(runid, hydroid, huc_level, dataset, scenprop, ds, save_directory, save_url, site)
###############################################

