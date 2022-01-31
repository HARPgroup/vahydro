#source("C:/Users/jklei/Desktop/GitHub/hydro-tools/R/om_model_table.R")
library('hydrotools')
library('jsonlite')
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
basepath='/var/www/R'
source('/var/www/R/config.R')

rseg_model_pid <- 4713208
fac_model_pid <- 4827216

fac_obj_url <- paste(json_obj_url, fac_model_pid, sep="/")
fac_model_info <- om_auth_read(fac_obj_url, token,  "text/json", "")
fac_model_info <- fromJSON(fac_model_info)

rseg_obj_url <- paste(json_obj_url, rseg_model_pid, sep="/")
rseg_model_info <- om_auth_read(rseg_obj_url, token,  "text/json", "")
rseg_model_info <- fromJSON(rseg_model_info)


#-------------------------------------------------------------------------------
rseg_table <- om_model_table(model_info = rseg_model_info,
                             runid.list = c('runid_11','runid_4011'),
                             metric.list = c("Qout","remaining_days_p0","l30_Qout",
                                             "l90_Qout","consumptive_use_frac","wd_cumulative_mgd","ps_cumulative_mgd",
                                             "wd_mgd","ps_mgd"),
                             include.elfgen = TRUE,
                             site = "http://deq1.bse.vt.edu:81/d.dh",
                             site_base = "http://deq1.bse.vt.edu:81"
)
rseg_table <- cbind(rownames(rseg_table),rseg_table)
names(rseg_table)[names(rseg_table) == 'rownames(rseg_table)'] <- 'Desc'
rseg_table_raw <- rseg_table

rseg_table_sql <- paste('SELECT
                  CASE
                    WHEN "Desc" = "model" THEN "River Segment Model Statistics:"
                    WHEN "Desc" = "Qout" THEN "Flow Out (cfs) - (i.e mean flow)"
                    WHEN "Desc" = "Qbaseline" THEN "Flow Baseline (cfs)"
                    WHEN "Desc" = "remaining_days_p0" THEN "Minimum Days of Storage Remaining"
                    WHEN "Desc" = "l30_Qout" THEN "30 Day Low Flow (cfs) (i.e drought flow)"
                    WHEN "Desc" = "l90_Qout" THEN "90 Day Low Flow (cfs) (i.e drought flow)"
                    WHEN "Desc" = "consumptive_use_frac" THEN "Consumptive Use Fraction"
                    WHEN "Desc" = "wd_cumulative_mgd" THEN "Cumulative Withdrawal (MGD)"
                    WHEN "Desc" = "ps_cumulative_mgd" THEN "Cumulative Point Source (MGD)"
                    WHEN "Desc" = "wd_mgd" THEN "Withdrawal (MGD)"
                    WHEN "Desc" = "ps_mgd" THEN "Point Source (MGD)"
                    ELSE Desc
                  END AS Description, *
                 FROM rseg_table_raw
                 WHERE Desc NOT IN ("riverseg","run_date","starttime","endtime","richness_change_abs","richness_change_pct")
                 ',sep='')
rseg_table <- sqldf(rseg_table_sql)
rseg_table <- rseg_table[,-2]
#-------------------------------------------------------------------------------

fac_table <- om_model_table(model_info = fac_model_info,
                            runid.list = c('runid_11','runid_4011'),
                            metric.list = c("base_demand_mgy", "wd_mgy", "unmet_demand_mgy","base_demand_mgd",
                                            "wd_mgd","ps_mgd","gw_demand_mgd","unmet30_mgd"),
                            site = "http://deq1.bse.vt.edu:81/d.dh",
                            site_base = "http://deq1.bse.vt.edu:81"
)
fac_table <- cbind(rownames(fac_table),fac_table)
names(fac_table)[names(fac_table) == 'rownames(fac_table)'] <- 'Desc'
fac_table_raw <- fac_table

fac_table_sql <- paste('SELECT
                  CASE
                    WHEN "Desc" = "model" THEN "Facility Model Statistics:"
                    WHEN "Desc" = "unmet30_mgd" THEN "Maximum 30 day potential unmet demand (MGD)"
                    WHEN "Desc" = "base_demand_mgy" THEN "Base Demand (MGY)"
                    WHEN "Desc" = "wd_mgy" THEN "Withdrawal (MGY)"
                    WHEN "Desc" = "unmet_demand_mgy" THEN "Unmet Demand (MGY)"
                    WHEN "Desc" = "base_demand_mgd" THEN "Requested Demand (MGD)"
                    WHEN "Desc" = "wd_mgd" THEN "Withdrawal Met (MGD)"
                    WHEN "Desc" = "ps_mgd" THEN "Point Source (MGD)"
                    WHEN "Desc" = "gw_demand_mgd" THEN "Groundwater Demand (MGD)"
                    ELSE Desc
                  END AS Description, *
                 FROM fac_table_raw
                 WHERE Desc NOT IN ("riverseg","run_date","starttime","endtime")
                 ',sep='')
fac_table <- sqldf(fac_table_sql)
fac_table <- fac_table[,-2]
#-------------------------------------------------------------------------------

statsdf <- rbind(rseg_table,fac_table)
