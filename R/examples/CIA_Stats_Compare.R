rm(list = ls())
library(httr)
library(hydrotools)
#site <- "http://deq2.bse.vt.edu/d.dh" 
site <- "http://deq1.bse.vt.edu/d.dh"
site_base <- "http://deq1.bse.vt.edu"
basepath <- '/var/www/R/'
source('/var/www/R/config.R')
options(timeout=1200)

################################################################################################
# USER INPUTS
################################################################################################
rseg.hydroid = 462757   #South Fork Powell River - Big Cherry Reservoir
fac.hydroid = 72672     #BIG STONE GAP WTP

#runid.list <- c('runid_201','runid_401','runid_6011','runid_6012')

runid.list <- c('runid_6013','runid_6015')
fac.metric.list <- c('wd_mgd','ps_mgd','unmet1_mgd','unmet7_mgd','unmet30_mgd','unmet90_mgd')
rseg.metric.list <- c('Qout','Qbaseline','remaining_days_p0','remaining_days_p10','remaining_days_p50','l30_Qout',
                      'l90_Qout','consumptive_use_frac','wd_cumulative_mgd','ps_cumulative_mgd')

################################################################################################
# RETRIEVE DATAFRAME OF FAC & RSEG MODEL STATS
################################################################################################
stats.df <- hydrotools::om_cia_table(rseg.hydroid = rseg.hydroid,
                                     fac.hydroid = fac.hydroid,
                                     runid.list = runid.list,
                                     fac.metric.list = fac.metric.list,
                                     rseg.metric.list =rseg.metric.list
)

View(stats.df)
pandoc.table(stats.df, style = "rmarkdown", split.table = 120)
#write.csv(stats.df,paste(export_path,'fac_rseg_stats.T.',gsub(":","",Sys.time()),'.csv',sep=''))
################################################################################################
################################################################################################
