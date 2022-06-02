basepath='/var/www/R'
source('/var/www/R/config.R')
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R") #Used during development

# rseg.hydroid <- params$rseg.hydroid
# runid.list <- params$runid.list
# rseg.metric.list <- params$rseg.metric.list

# rseg.hydroid <- 67839 #Roanoke River (Wayside Park)
# rseg.hydroid <- 68327 #Roanoke River (Salem)
# rseg.hydroid <- 68099 #Tinker Creek
# rseg.hydroid <- 68376 #Catawba Creek
# rseg.hydroid <- 68126 #Carvins Cove Reservoir

rseg.hydroids <- c(67839,68327,68099,68376,68126)
# runid.list <- c("runid_2011","runid_4011","runid_600")
runid.list <- c("runid_6011")
rseg.metric.list <- c("Qout","l30_Qout","l90_Qout","consumptive_use_frac",
                      "wd_cumulative_mgd","ps_cumulative_mgd",
                      "wd_mgd","ps_mgd")

rseg_stats_table <- function (rseg.hydroid,runid.list,rseg.metric.list,site,omsite){
  
  rseg.model <- om_get_model(site, rseg.hydroid)
  rseg_obj_url <- paste(json_obj_url, rseg.model$pid, sep="/")
  rseg_model_info <- om_auth_read(rseg_obj_url, token,  "text/json", "")
  rseg_model_info <- fromJSON(rseg_model_info)
  
  
  rseg_table <- om_model_table(model_info = rseg_model_info,
                               runid.list = runid.list,
                               metric.list = rseg.metric.list,
                               include.elfgen = TRUE,
                               site = site,
                               site_base = omsite
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
                   WHERE Desc NOT IN ("riverseg","run_date","starttime","endtime","richness_change_abs","richness_change_pct","runid")
                   ',sep='')
  rseg_table <- sqldf(rseg_table_sql)
  rseg_table <- rseg_table[,-2]
  # colnames(rseg_table) <- colnames(fac_table) #Col names need to match before rbind
  #-------------------------------------------------------------------------------
  # statsdf <- rbind(rseg_table,fac_table)
  return(rseg_table)
}

rseg_table <- data.frame()
#i <- 2
for (i in 1:length(rseg.hydroids)){
  rseg.hydroid <- rseg.hydroids[i]
  rseg_table_i <- rseg_stats_table(rseg.hydroid,runid.list,rseg.metric.list,site,omsite)
  rseg_table <- rbind(rseg_table,rseg_table_i)
}



