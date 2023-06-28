library('hydrotools')
library('zoo')
library("nhdplusTools")
library("sf")
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
# rmarkdown::render('C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', params = list( rseg.hydroid = 68113, fac.hydroid = 73024, runid.list = c("runid_400","runid_600"), intake_stats_runid = 11,upstream_rseg_ids=c(68113) ))
# river
rpid = 4711947
rhid = 68367
ielid = 211997 # Lake meade reservoir
# facility
fpid = 4824108
fhid = 67337
felid = 347378
# Western Branch facility
wbfelid = 353093
# runoff (for checking)
roelid = 279207
relid = 211959 
# Western Branch Reservoir, river segment
wbrelid = 210135
wbrcelid = 210171
# Western Branch reservoir elid
wbielid = 210173

# NHD Prep
out_point = sf::st_sfc(sf::st_point(c(-76.603617, 36.729932)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
# 5.358322
m_cat <- plot_nhdplus(list(nhd_out$comid))
nhd <- get_nhdplus(m_cat$basin)
trib_comids = get_UT(nhd, nhd_out$comid, distance = NULL)
nhd_df <- as.data.frame(st_drop_geometry(nhd))

length_ft = as.numeric(sqldf(paste("select sum(lengthkm) from nhd_df where streamorde =",nhd_out$streamorde ))) * 3280.84
da_sqmi = nhd_out$totdasqkm / 2.58999
cslope = as.numeric(sqldf(paste("select sum(slope * totdasqkm)/sum(totdasqkm) from nhd_df where slope >= 0 and streamorde =",nhd_out$streamorde )))
print(paste("length_ft, da_sqmi, cslope", length_ft, da_sqmi, cslope))


datr11 <- om_get_rundata(relid, 11, site = omsite)
quantile(datr11$Runit)
datr401 <- om_get_rundata(relid, 401, site = omsite)
datr6 <- om_get_rundata(relid, 600, site = omsite)
datr801 <- om_get_rundata(relid, 801, site = omsite)
bccc <- as.data.frame(
  datbc602[,
           c("impoundment_use_remain_mg",
             "impoundment_days_remaining",
             "bc_release_cfs")
  ]
)

datwbr4 <- om_get_rundata(wbrelid, 401, site = omsite)
quantile(datwbr4$wd_imp_child_mgd)
quantile(datwbr4$wd_cumulative_mgd)
datwbf4 <- om_get_rundata(wbfelid, 401, site = omsite)
quantile(datwbf4$base_demand_pstatus_mgd)
quantile(datwbf4$wd_mgd)
datwbi4 <- om_get_rundata(wbielid, 401, site = omsite)
quantile(datwbi4$release_cfs)
quantile(datwbi4$et_in)
quantile(datwbi4$Qin)

datwbc4 <- om_get_rundata(wbrcelid, 401, site = omsite)
quantile(datwbc4$Qout)

dati2 <- om_get_rundata(ielid, 2, site = omsite)
dati4 <- om_get_rundata(ielid, 400, site = omsite)
dati6 <- om_get_rundata(ielid, 600, site = omsite)
quantile(dati4$use_remain_mg)
quantile(dati6$release_cfs,probs=c(0.0,0.05,0.10,0.25,0.5))
quantile(dati6$flowby,probs=c(0.0,0.05,0.10,0.25,0.5))
quantile(dati6$release,probs=c(0.0,0.05,0.10,0.25,0.5))

kable(quantile(dati2$evap_mgd), 'markdown')


datf4 <- om_get_rundata(felid, 401, site = omsite)
quantile(datf4$available_mgd)
quantile(datf4$wd_mgd)
quantile(datf4$base_demand_pstatus_mgd)
datf2 <- om_get_rundata(felid, 2, site = omsite)
quantile(datf2$available_mgd)
quantile(datf2$wd_mgd)
quantile(datf2$base_demand_pstatus_mgd)
quantile(datf2$gw_sw_factor)
quantile(datf2$fac_demand_mgd)
quantile(datf2$flowby_proposed)

datf6 <- om_get_rundata(felid, 601, site = omsite)
quantile(datf6$available_mgd)
quantile(datf6$wd_mgd)
quantile(datf6$base_demand_pstatus_mgd)
quantile(datf6$flowby_mif)
quantile(datf6$flowby_proposed)
quantile(datf6$Qreach)
quantile(datf6$impoundment_release_cfs, probs=c(0.0,0.05,0.10,0.25,0.5))

