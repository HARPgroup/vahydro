library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# river
rpid = 4708935
rhid = 68144
relid = 277694  

datr401 <- om_get_rundata(relid, 401, site = omsite)
datr601 <- om_get_rundata(relid, 601, site = omsite)
bccc <- as.data.frame(
  datbc602[,
    c("impoundment_use_remain_mg",
      "impoundment_days_remaining",
      "bc_release_cfs")
  ]
)

# facility
fpid = 4825354
fhid = 72194
felid = 277738 

datf11 <- om_get_rundata(felid, 11, site = omsite)
datf13 <- om_get_rundata(felid, 13, site = omsite)
datf401 <- om_get_rundata(felid, 401, site = omsite)
datf601 <- om_get_rundata(felid, 601, site = omsite)
quantile(datf601$Qreach,probs=c(0,0.01,0.05,0.10, 0.25,0.5))
quantile(datf601$Qintake,probs=c(0,0.01,0.05,0.10, 0.25,0.5))

rmarkdown::render(
  '/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  params = list( 
    rseg.hydroid = rhid, fac.hydroid = fhid, 
    runid.list = c("runid_11", "runid_401"), 
    intake_stats_runid = 11
  ) 
)
roelid = 276234
datrof401 <- om_get_rundata(roelid, 401, site = omsite)

dev.off()
hydroTSM::fdc(
  cbind(datf6011$Qnatural, datf6001$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datf6011$Qnatural, datf6011$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datf600$Qnatural, datf600$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datf6014$Qnatural, datf6014$Qintake),
  yat = c(1,5,10,25,100,400)
)


[runid_600:wd_cumulative_mgd]

hydroTSM::fdc(cbind(datf4011$Qnatural, datf4011$Qintake))
hydroTSM::fdc(cbind(datf601$Qnatural, datf601$Qintake))
hydroTSM::fdc(cbind(datf6013$Qnatural, datf6013$Qintake))
hydroTSM::fdc(cbind(datf6014$Qnatural, datf6014$Qintake))
cccc <- as.data.frame(
  datf6013[,c(
    "Qnatural",
    "discharge_mgd",
    "flowby_pof",
    "flowby",
    "bc_release_cfs",
    "Qintake",
    "available_mgd",
    "wd_mgd",
    "unmet_demand_mgd",
    "reservoir_use_remain_mg")]
  )
hydroTSM::fdc(cccc)
datf6013[300:370,c('Qnatural', 'reservoir_use_remain_mg', 'bc_release_cfs')]

sample <- rbind(as.data.frame(datf600[5813,]),as.data.frame(datf6011[700,]))
xcsam <- as.data.frame(
  sample[,c(
    "Qnatural",
    "discharge_mgd",
    "flowby_pof",
    "flowby",
    "bc_release_cfs",
    "Qintake",
    "available_mgd",
    "wd_mgd",
    "unmet_demand_mgd",
    "reservoir_use_remain_mg")]
)

fdc(cbind(datf401$Qnatural, datf401$Qintake))

datf602 <- om_get_rundata(felid, 602, site = omsite)
datf6012 <- om_get_rundata(felid, 6012, site = omsite)
datf6013 <- om_get_rundata(felid, 6013, site = omsite)
om_ts_diff(datf6012, datf6013, "reservoir_use_remain_mg", "reservoir_use_remain_mg")

