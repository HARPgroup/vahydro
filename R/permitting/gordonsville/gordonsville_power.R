library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/imp_utils.R")

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

# assuming the reservoir is conical in shape
# surface area max = 12 acres = 522720 sqft
sa_a = 522720
r_a = sqrt(sa_a/pi)
y_a = 70

# surface area b = 11 acres = 479375 sqft
sa_b = 479375
r_b = sqrt(sa_b/pi)
y_b = 63

# surface area c = 7.64 acres = 332750 sqft
# 524000 - 6375*(70-40)
sa_c = 332750
r_c = sqrt(sa_c/pi)
y_c = 40

# surface area d = 3.98 acres = 173375 sqft 
# 524000 - 6375*(70-15)
sa_d = 173375
r_d = sqrt(sa_d/pi)
y_d = 15

# imp_geom = data.frame(
#   x = c(0, r_a - r_b, r_b - r_c, r_a, r_a + r_c, r_a + r_b, r_a + r_a),
#   y = c(y_a, y_b, y_c, 0, y_c, y_b, y_a)
# )
imp_geom = data.frame(
  x = c(0, r_a - r_b, r_b - r_c, r_b - r_d, r_a, r_a + r_d, r_a + r_c, r_a + r_b, r_a + r_a),
  y = c(y_a, y_b, y_c, y_d, 0, y_d, y_c, y_b, y_a)
)
plot(imp_geom,xlab="ft",ylab="ft",xaxt = 'n',pch=16)
lines(imp_geom, type = "l", lty = 1)
axis(1, at = seq(0, 1000, by = 50), las=2)

# dev.off(dev.list()["RStudioGD"])


#########################
# vol calcs: 

# top_cylinder = pi*(r_a^2)*7
# partial_cone = (1/3)*pi*(y_b-y_c)*((r_b^2) + r_b*r_c + (r_c^2))
# bottom_cone = pi*(r_c^2)*(1/3)*y_c
# total_vol_cubic_ft = top_cylinder+partial_cone+bottom_cone
# total_vol_acft = total_vol_cubic_ft/43560
# 
# top_cylinder/43560
# (partial_cone+bottom_cone)/43560
# bottom_cone/43560

partial_cone_1 = (1/3)*pi*(y_a-y_b)*((r_a^2) + r_a*r_b + (r_b^2))
partial_cone_2 = (1/3)*pi*(y_b-y_c)*((r_b^2) + r_b*r_c + (r_c^2))
partial_cone_3 = (1/3)*pi*(y_c-y_d)*((r_c^2) + r_c*r_d + (r_d^2))
complete_cone_4 = pi*(r_d^2)*(1/3)*y_d
# partial_cone_4 = (1/3)*pi*(y_d-y_e)*((r_d^2) + r_d*r_e + (r_e^2))

complete_cone_4/43560
(complete_cone_4+partial_cone_3)/43560
(complete_cone_4+partial_cone_3+partial_cone_2)/43560

total_vol_cubic_ft = partial_cone_1+partial_cone_2+partial_cone_3+complete_cone_4
total_vol_acft = total_vol_cubic_ft/43560
################################################################################################
################################################################################################

# this will show the runs going on 
# ps ax|grep run_

# clear run
# php fn_clearRun.php 252117 401

################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 207771 # South Anna River
fac_om_id <- 284961  # Gordonsville Power Station:South Anna River
runid <- 401
# runid <- 4011
################################################################################################

facdat <- om_get_rundata(fac_om_id, runid, site = omsite, hydrowarmup = FALSE)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat$pct_use_remain <- 3.07*facdat$local_impoundment_use_remain_mg / facdat$local_impoundment_max_usable
# 3.07 is the ac-ft conversion

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

sort(colnames(rsegdat_df))
sort(colnames(facdat_df))

#-------------------------------------------------------------------------
gord <- om_quantile_table(facdat_df, metrics = c("vwp_max_mgy","vwp_max_mgd","wd_mgd",
                                               "unmet_demand_mgd","adj_demand_mgd",
                                               "local_impoundment_area","local_impoundment_days_remaining", 
                                               "local_impoundment_demand","local_impoundment_demand_met_mgd", 
                                               "local_impoundment_evap_mgd",            
                                               "local_impoundment_lake_elev","local_impoundment_max_usable",     
                                               "local_impoundment_precip_mgd","local_impoundment_Qin",            
                                               "local_impoundment_Qout","local_impoundment_refill",         
                                               "local_impoundment_refill_full_mgd","local_impoundment_release",        
                                               "local_impoundment_spill",        
                                               "local_impoundment_Storage","local_impoundment_use_remain_mg",
                                               "refill_pump_mgd","refill_plus_demand","refill_available_mgd","refill_max_mgd",
                                               "flowby","Qintake","pct_use_remain"),
                         rdigits = 3)


kable(gord)

round(quantile(rsegdat_df$Qout,c(0,0.1,0.25,0.5,0.75,0.9,1.0)), 3)

################################################################################################
################################################################################################

imp_model_query <- "SELECT year, month, day,
                          vwp_base_mgd, 
                          wd_mgd, 
                          local_impoundment_lake_elev, local_impoundment_Storage, pct_use_remain
                    FROM facdat_df"
imp_analysis <- sqldf(imp_model_query)
head(imp_analysis)
################################################################################################
################################################################################################

fn_plot_impoundment_flux(facdat,"pct_use_remain","local_impoundment_Qin", "local_impoundment_Qout", "wd_mgd")


################################################################################################
################################################################################################

# number of years in simulation: 
nyears = nrow(facdat_df)/365

# wd_mgd should not exceed the Maximum Annual Withdrawal Limit 13.43 mgy
sum(facdat_df$wd_mgd)/nyears




################################################################################################
################################################################################################
