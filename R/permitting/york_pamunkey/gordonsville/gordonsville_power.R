library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/imp_utils.R")

# ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
# ds$get_token(rest_pw)

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

partial_cone_1 = (1/3)*pi*(y_a-y_b)*((r_a^2) + r_a*r_b + (r_b^2))
partial_cone_2 = (1/3)*pi*(y_b-y_c)*((r_b^2) + r_b*r_c + (r_c^2))
partial_cone_3 = (1/3)*pi*(y_c-y_d)*((r_c^2) + r_c*r_d + (r_d^2))
complete_cone_4 = pi*(r_d^2)*(1/3)*y_d

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
runid <- 400
# runid <- 401
# runid <- 402
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
gord <- om_quantile_table(facdat, metrics = c("vwp_max_mgy","vwp_max_mgd","wd_mgd", "discharge_mgd",
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
                                               "flowby","Qintake","Qintake_mgd","drawdown_mgd","quarry_inflow_mgd",
                                               "pct_use_remain"),
                         rdigits = 3)


kable(gord)

gord <- om_quantile_table(
  facdat, 
  metrics = c(
    "vwp_max_mgy","vwp_max_mgd","wd_mgd", "discharge_mgd",
    "local_impoundment_demand","local_impoundment_demand_met_mgd", 
    "local_impoundment_evap_mgd", "Qintake_post",
    "flowby","Qintake","Qintake_mgd","drawdown_mgd","quarry_inflow_mgd"
  ),
   rdigits = 3)


kable(gord)


facdat_df$vwp_max_mgd

CU <- om_quantile_table(
  facdat, 
  metrics = c(
    "quarry_inflow_mgd", "Qintake", 
    "Qintake_post","Runit",
    "local_impoundment_lake_elev",
    "local_impoundment_evap_mgd"
  ),
  rdigits = 3
)

kable(CU, 'markdown')
CU_query <- "SELECT year, month, day,
                          quarry_inflow_mgd,
                          quarry_inflow_mgd * 1.547, 
                          Qintake, 
                          Qintake_post,
                          wd_mgd,
                          discharge_mgd,
                          quarry_inflow_mgd - wd_mgd
                    FROM facdat_df"
cu_analysis <- sqldf(CU_query)

om_flow_table(facdat_df, q_col = "wd_mgd", rdigits=3)
om_flow_table(facdat_df, q_col = "local_impoundment_evap_mgd", rdigits=3)
om_flow_table(facdat_df, q_col = "quarry_inflow_mgd", rdigits=3)
om_flow_table(facdat_df, q_col = "Qintake_post", rdigits=3)

################################################################################################
################################################################################################
unmet_query <- "SELECT year, month, day,
                          base_demand_mgd,
                          wd_mgd,
                          unmet_demand_mgd,
                          max_mgd,available_mgd,adj_demand_mgd,
                          drought_pct, rejected_demand_pct
                    FROM facdat_df
                    WHERE year = 2019 AND month = 10

                "
# WHERE year = 2002 AND month = 8
#WHERE year = 2019 AND month = 10
unmet_analysis <- sqldf(unmet_query)
head(unmet_analysis)
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
# point source investigations: 
om_quantile_table(facdat_df, metrics = c("wd_mgd","discharge_mgd"),rdigits = 3)
mean(facdat_df$wd_mgd)
mean(facdat_df$discharge_mgd)

ps_query <- "SELECT year, month, day,
                          wd_mgd, 
                          discharge_mgd, 
                          wd_mgd * 0.985 AS calc
                    FROM facdat_df"
ps_analysis <- sqldf(ps_query)
sum(ps_analysis$discharge_mgd)
sum(ps_analysis$calc)
#--------------------------------------

library(echor)
id_df <- data.frame("id" = c('VA0087033'))
dmr <- echor::downloadDMRs(id_df, idColumn=id)
dmr_df <- as.data.frame(dmr$dmr)
# sort(colnames(dmr_df))

dmr_df[['datetime']] <- as.POSIXct(dmr_df[['monitoring_period_end_date']],format = "%m/%d/%Y")
# dmr_df[['month']] <- stringr::str_remove(format(as.Date(dmr_df$datetime, format="%d/%m/%Y"),"%m"), "^0+")
dmr_df[['month']] <- format(as.Date(dmr_df$datetime, format="%d/%m/%Y"),"%m")
dmr_query <- "SELECT npdes_id, perm_feature_nmbr, monitoring_period_end_date, datetime, month, 
                     statistical_base_code, statistical_base_short_desc,
                     dmr_value_standard_units, standard_unit_desc
              FROM dmr_df
              WHERE perm_feature_type_code = 'EXO'
                AND parameter_code = 50050
                AND statistical_base_code = 'MK'
              ORDER BY datetime DESC  
             "
dmr_analysis <- sqldf(dmr_query)
dmr_analysis$dmr_value_standard_units <- as.numeric(dmr_analysis$dmr_value_standard_units)

# monthly discharge figures
# ECHO ----------------------------------------------------------------------------
startdate <- as.character(min(dmr_analysis$datetime))
enddate <- as.character(max(dmr_analysis$datetime))
modat <- sqldf("select month, avg(dmr_value_standard_units) as dmr_value_standard_units from dmr_analysis group by month order by month ASC")
fname <- paste(export_path,paste0('fig.monthly_discharge_echo.',id_df$id, '001.png'),sep = '')
png(fname)
barplot(modat$dmr_value_standard_units ~ modat$month, ylim=c(0,0.1),
        xlab="Month", ylab="Outfall Discharge (mgd)",
        main=paste0("Outfall Discharge\nECHO Reported: ", id_df$id,"001\n(",startdate," - ",enddate,")"))
dev.off()
# VAHYDRO ----------------------------------------------------------------------------
modat <- sqldf("select month, avg(discharge_mgd) as discharge_mgd from facdat_df group by month order by month ASC")
modat$month <- c("01","02","03","04","05","06","07","08","09","10","11","12")
fname <- paste(export_path,paste0('fig.monthly_discharge_model.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
# barplot(modat$discharge_mgd ~ modat$month, ylim=c(0,0.1),
barplot(modat$discharge_mgd ~ modat$month,
        xlab="Month", ylab="Outfall Discharge (mgd)",
        main=paste0("Outfall Discharge\nVAHydro Modeled: ", fac_om_id," ",runid,"\n(",mstart," - ",mend,")"))
dev.off()


# VAHYDRO REPORTED WD----------------------------------------------------------------------------
# sort(colnames(facdat_df))
# facdat_df$current_mgy
# facdat_df$historic_monthly_pct
# facdat_df$current_mgy 
# options(scipen=999)
# modat <- sqldf("select month,
#                avg(current_mgy)*historic_monthly_pct/365 as current_mgd
#                from facdat_df
#                group by month
#                order by month ASC")
modat <- sqldf("select month, avg(current_mgd) as current_mgd from facdat_df group by month order by month ASC")
modat$month <- c("01","02","03","04","05","06","07","08","09","10","11","12")
fname <- paste(export_path,paste0('fig.monthly_withdrawal_reported.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
barplot(modat$current_mgd ~ modat$month, ylim=c(0,0.1),
        xlab="Month", ylab="Intake Withdrawal (mgd)",
        main=paste0("Intake Withdrawal\nVAHydro Reported: ", fac_om_id," ",runid,"\n(",mstart," - ",mend,")"))
dev.off()

################################################################################################
################################################################################################
# revised refill_max_mgd  equation 8/23/23:
sort(colnames(facdat_df))

discharge_analysis <- om_quantile_table(facdat_df, metrics = c("refill_pump_mgd","refill_plus_demand","refill_available_mgd","refill_max_mgd",
                                                               "quarry_inflow_mgd","wd_mgd","cova_withdrawal","discharge_mgd"),rdigits = 3)
kable(discharge_analysis)

refill_query <- "SELECT year, month, day,
                              refill_max_mgd,
                              quarry_inflow_mgd,
                              discharge_mgd,
                              quarry_inflow_mgd + discharge_mgd,
                              round((quarry_inflow_mgd + discharge_mgd - refill_max_mgd),7)
                    FROM facdat_df
                    "
refill_analysis <- sqldf(refill_query)

sort(colnames(rsegdat_df))
discharge_analysis <- om_quantile_table(rsegdat_df, metrics = c("ps_mgd","ps_cumulative_mgd","ps_trib_mgd",
                                                               "ps_upstream_mgd","ps_nextdown_mgd"),
                                        rdigits = 3)
kable(discharge_analysis)



imp_out <- om_quantile_table(facdat_df, metrics = c("Qintake_mgd", "drawdown_mgd", "quarry_inflow_mgd", 
                                                    "discharge_mgd", "refill_max_mgd" ,"local_impoundment_Qout",
                                                    "local_impoundment_lake_elev","Runit","precip_in"),rdigits = 3)
kable(imp_out)

imp_out_query <- "SELECT year, month, day,
                              quarry_inflow_mgd,
                              local_impoundment_Qout,
                              Runit,
                              precip_in
                    FROM facdat_df
                    "
imp_out_analysis <- sqldf(imp_out_query)

sort(colnames(facdat_df))

################################################################################################
################################################################################################
# precip figures
modat <- sqldf("select month, avg(precip_in) as precip_in from facdat_df group by month")
fname <- paste(export_path,paste0('fig.precip_in.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
barplot(modat$precip_in ~ modat$month, ylim=c(0,0.05),
        xlab="Month", ylab="precip_in",main="")
# ylim = c(0, 0.05))
dev.off()

precip_df <- facdat_df
precip_df$date <- row.names(precip_df) 
fname <- paste(export_path,paste0('fig.precip_in_scatter.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
plot(as.Date(precip_df$date), precip_df$precip_in, type = "b", pch = 19, 
     col = "red", xlab = "Model Flow Period", ylab = "precip_in",main="facdat_df$precip_in")
dev.off()
################################################################################################
################################################################################################
# source("C:/Users/nrf46657/Desktop/GitHub/hydro-tools/R/imp_utils.R") # for dev only
fname <- paste(export_path,paste0('dev_imp_storage.',fac_om_id, '.', runid, '.png'),sep = '')
# png(fname, width = 480, height = 480)
png(fname)
fn_plot_impoundment_flux(facdat,"pct_use_remain","local_impoundment_Qin", "local_impoundment_Qout", "wd_mgd")
dev.off()

################################################################################################
################################################################################################

# number of years in simulation: 
nyears = nrow(facdat_df)/365

# wd_mgd should not exceed the Maximum Annual Withdrawal Limit 13.43 mgy
sum(facdat_df$wd_mgd)/nyears

################################################################################################
################################################################################################
# monthly demand analysis 
sort(colnames(facdat_df))

historic_use_query <- "SELECT month,historic_monthly_pct,
                              vwp_max_mgy,
                              vwp_base_mgd,
                              vwp_max_mgd,
                              vwp_demand_mgd,
                              avg(Qintake_mgd)
                    FROM facdat_df
                    GROUP BY month
                    "
historic_use <- sqldf(historic_use_query)


inflow_query <- "SELECT month,
                        avg(quarry_inflow_mgd),
                        avg(vwp_base_mgd),
                        avg(Qintake_mgd),
                        (avg(quarry_inflow_mgd)/avg(Qintake_mgd))*100
                    FROM facdat_df
                    GROUP BY month
                    "
inflow <- sqldf(inflow_query)



################################################################################################
################################################################################################
# monthly inflow figure 
modat <- sqldf("select month, avg(quarry_inflow_mgd) as quarry_inflow_mgd from facdat_df group by month")

fname <- paste(export_path,paste0('fig.monthly_inflow.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
barplot(modat$quarry_inflow_mgd ~ modat$month,
        xlab="Month", ylab="Quarry Inflow (mgd)",main="Subsurface Inflow From South Anna River")
        # ylim = c(0, 0.05))
dev.off()
################################################################################################
################################################################################################
# impoundment evap figure 
# sort(colnames(facdat_df))
modat <- sqldf("select month, avg(local_impoundment_evap_mgd) as local_impoundment_evap_mgd from facdat_df group by month")

fname <- paste(export_path,paste0('fig.monthly_impoundment_evap.',fac_om_id, '.', runid, '.png'),sep = '')
png(fname)
barplot(modat$local_impoundment_evap_mgd ~ modat$month,
        xlab="Month", ylab="Impoundment Evaporation (mgd)",main="Impoundment Evaporation")
# ylim = c(0, 0.05))
dev.off()
################################################################################################
################################################################################################
