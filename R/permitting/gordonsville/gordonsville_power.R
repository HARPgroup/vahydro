library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")


################################################################################################
################################################################################################
# Quarry NHDPlus Feature
library('nhdplusTools')
library('wellknown')
nhdplus_id = 8566243
wb = nhdplusTools::get_waterbodies(id = nhdplus_id)
wb_wkt = wellknown::sf_convert(wb$geometry)
plot(wb$geometry)
wb$areasqkm

# assuming the reservoir is circular in shape
# surface area max = 12 acres = 522720 sqft
sa_max = 522720
r_max = sqrt(sa_max/pi)

# surface area mid = 8 acres = 348480 sqft
sa_mid = 348480
r_mid = sqrt(sa_mid/pi)

# imp_geom = data.frame(x=c(0,2,6,10,12),y=c(7,4,0,4,7))
imp_geom = data.frame(x=c(0,r_max-r_mid,r_max,r_max+r_mid,r_max+r_max),y=c(7,4,0,4,7))
plot(imp_geom,xlab="ft",ylab="ft",xaxt = 'n')
lines(imp_geom, type = "l", lty = 1)
axis(1, at = seq(0, 800, by = 50), las=2)

dev.off(dev.list()["RStudioGD"])
################################################################################################
################################################################################################

# this will show the runs going on 
# ps ax|grep run_

# clear run
# php fn_clearRun.php 252117 401

# SML Impoundment:



# max(SMLdat$trigger1)
# ##############################################################################SML_om_id <- 252119 
# # runid <- 401
# runid <- 400
# SML_om_id <- 252119
# SMLdat <- om_get_rundata(SML_om_id, runid, site = omsite)
# SMLdat_df <- data.frame(SMLdat)
# sort(colnames(SMLdat_df))
# 
# SML_imp <- om_quantile_table(SMLdat_df, metrics = c("impoundment_demand","impoundment_demand_met_mgd",'impoundment_lake_elev',"impoundment_Storage","impoundment_use_remain_mg","impoundment_days_remaining","impoundment_Qin","impoundment_Qout",
#                                                     "Leesville_Lake_demand","Leesville_Lake_demand_met_mgd","Leesville_Lake_lake_elev","Leesville_Lake_Storage","Leesville_Lake_use_remain_mg","Leesville_Lake_days_remaining","Leesville_Lake_Qin","Leesville_Lake_Qout","Leesville_Lake_release","Leesville_Lake_refill_full_mgd",
#                                                     "wd_mgd","pump_lees","refill_lees","Qin","Qout","release_sml","sml_use_remain_mg",
#                                                     "trigger1","trigger2","trigger3","trigger3_tbl","trigger_level","Qbrook","Rbrook","Tbrook","lees_min",
#                                                     "sml_elev"
#                                                     ),rdigits = 2)
# kable(SML_imp,'markdown')
# 
# 
# test <- sqldf("SELECT year, month, day, sml_elev, trigger1, trigger2, trigger3, trigger3_tbl, trigger_level
#                 FROM SMLdat_df
#                 ORDER BY sml_elev
#               ")
# 
# 
################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 207771 # South Anna River
fac_om_id <- 284961  # Gordonsville Power Station:South Anna River
runid <- 401
################################################################################################

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

sort(colnames(rsegdat_df))
sort(colnames(facdat_df))

#-------------------------------------------------------------------------

gord <- om_quantile_table(facdat_df, metrics = c("vwp_max_mgy","vwp_max_mgd","wd_mgd",
                                               "unmet_demand_mgd",
                                               "local_impoundment_area","local_impoundment_days_remaining", 
                                               "local_impoundment_demand","local_impoundment_demand_met_mgd", 
                                               "local_impoundment_evap_mgd",            
                                               "local_impoundment_lake_elev","local_impoundment_max_usable",     
                                               "local_impoundment_precip_mgd","local_impoundment_Qin",            
                                               "local_impoundment_Qout","local_impoundment_refill",         
                                               "local_impoundment_refill_full_mgd","local_impoundment_release",        
                                               "local_impoundment_spill",        
                                               "local_impoundment_Storage","local_impoundment_use_remain_mg"),
                         rdigits = 3)


kable(gord)

################################################################################################
################################################################################################

# number of years in simulation: 
nyears = nrow(facdat_df)/365

# wd_mgd should not exceed the Maximum Annual Withdrawal Limit 13.43 mgy
sum(facdat_df$wd_mgd)/nyears




################################################################################################
################################################################################################
