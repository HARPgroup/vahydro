library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 210815
fac_om_id <- 351042
runid <- 601
################################################################################################


facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

# om_flow_table(rsegdat_df, "wd_cumulative_mgd")

Qintake = quantile(facdat_df$Qintake, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
mif_monthly = quantile(facdat_df$mif_monthly, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
available_mgd = quantile(facdat_df$available_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
wd_mgd = quantile(facdat_df$wd_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
adj_demand_mgd = quantile(facdat_df$adj_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
refill_pump_mgd = quantile(facdat_df$refill_pump_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
wd_net_mgd = quantile(facdat_df$wd_net_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

round(rbind(Qintake,
            mif_monthly,
            available_mgd,
            wd_mgd,
            adj_demand_mgd,
            refill_pump_mgd,
            wd_net_mgd),2)
