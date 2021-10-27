library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# container
pid =
elid = 352123

datbcr <- list()
datbcr400 <- om_get_rundata(247387, 400, site = omsite)
datbcr600 <- om_get_rundata(247387, 600, site = omsite)
datbcr6001 <- om_get_rundata(247387, 6001, site = omsite)
datbcr6012 <- om_get_rundata(247387, 6012, site = omsite)
datbcr4011 <- om_get_rundata(247387, 4011, site = omsite)
datbcr6011 <- om_get_rundata(247387, 6011, site = omsite)
datbcr400[5813,]$Runit
datbcr600[5813,]$Runit
datbcr4011[700,]$Runit
datbcr6011[700,]$Runit
datbcr6012[700,]$Runit
datbcr6001[5813,]$Runit

# river
pid = 5831933
elid = 352078
runid = 6013

# facility
pid = 4826467
elid = 247415
runid = 6013


datbc201 <- om_get_rundata(352078, 201, site = omsite)
datbc301 <- om_get_rundata(352078, 301, site = omsite)
datbc4011 <- om_get_rundata(352078, 4011, site = omsite)
datbc400 <- om_get_rundata(352078, 400, site = omsite)
datbc600 <- om_get_rundata(352078, 600, site = omsite)
datbc401 <- om_get_rundata(352078, 401, site = omsite)
datbc601 <- om_get_rundata(352078, 601, site = omsite)
datbc602 <- om_get_rundata(352078, 602, site = omsite)
datbc6011 <- om_get_rundata(352078, 6011, site = omsite)
datbc6014 <- om_get_rundata(352078, 6014, site = omsite)
bccc <- as.data.frame(
  datbc602[,
    c("impoundment_use_remain_mg",
      "impoundment_days_remaining",
      "bc_release_cfs")
  ]
)

datbcfac4011 <- om_get_rundata(247415, 4011, site = omsite)
datbcfac201 <- om_get_rundata(247415, 201, site = omsite)
datbcfac301 <- om_get_rundata(247415, 301, site = omsite)
datbcfac401 <- om_get_rundata(247415, 401, site = omsite)
datbcfac6011 <- om_get_rundata(247415, 6011, site = omsite)
datbcfac600 <- om_get_rundata(247415, 600, site = omsite)
datbcfac6012 <- om_get_rundata(247415, 6012, site = omsite)
datbcfac6001 <- om_get_rundata(247415, 6001, site = omsite)

datbcfac601 <- om_get_rundata(247415, 601, site = omsite)
datbcfac6014 <- om_get_rundata(247415, 6014, site = omsite)
quantile(datbcfac602$available_mgd,probs=c(0,0.01,0.05,0.10, 0.25,0.5))


dev.off()
hydroTSM::fdc(
  cbind(datbcfac6011$Qnatural, datbcfac6001$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datbcfac6011$Qnatural, datbcfac6011$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datbcfac600$Qnatural, datbcfac600$Qintake),
  yat = c(1,5,10,25,100,400)
)
hydroTSM::fdc(
  cbind(datbcfac6014$Qnatural, datbcfac6014$Qintake),
  yat = c(1,5,10,25,100,400)
)


[runid_600:wd_cumulative_mgd]

hydroTSM::fdc(cbind(datbcfac4011$Qnatural, datbcfac4011$Qintake))
hydroTSM::fdc(cbind(datbcfac601$Qnatural, datbcfac601$Qintake))
hydroTSM::fdc(cbind(datbcfac6013$Qnatural, datbcfac6013$Qintake))
hydroTSM::fdc(cbind(datbcfac6014$Qnatural, datbcfac6014$Qintake))
cccc <- as.data.frame(
  datbcfac6013[,c(
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
datbcfac6013[300:370,c('Qnatural', 'reservoir_use_remain_mg', 'bc_release_cfs')]

sample <- rbind(as.data.frame(datbcfac600[5813,]),as.data.frame(datbcfac6011[700,]))
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

write.table(sample,"c:/WorkSpace/tmp/bsg_600_vs_6012.csv",sep=",")
#Compare mean flowby with 15% pof and 0.5 MGD when flow < 6 cfs
sqldf(
  "select avg(Qnatural), avg(0.25 * Qnatural) AS flowby_25pct, 0.5 * 1.547 as p0_pt_5_mgd
   from cccc
  where Qnatural < (4 * 0.5 * 1.547)")

sqldf(
  "select avg(Qnatural), avg(0.25 * Qnatural), 0.5 * 1.547 as p0_pt_5_mgd
   from cccc
  where Qnatural >= 6.0 and Qnatural < 15.0 ")

sqldf(
  "select avg(Qnatural), avg(0.25 * Qnatural), 0.5 * 1.547 as p0_pt_5_mgd,
  count(*) as num_days
   from cccc
  where (0.25 * Qnatural) < (0.5 * 1.547) ")

# ro container = 247387
# ro cbp5 = 347582
ro6014 <- om_get_rundata(347582,  6014, site = omsite)
ro601 <- om_get_rundata(347582,  601, site = omsite)
ro602 <- om_get_rundata(347582,  602, site = omsite)
ro6012 <- om_get_rundata(347582,  6012, site = omsite)
ro600 <- om_get_rundata(347582,  600, site = omsite)
ro6011 <- om_get_rundata(347582,  6011, site = omsite)
ro6013 <- om_get_rundata(347582,  6013, site = omsite)
quantile(ro6012$Qunit)
quantile(ro6013$Qunit)
hydroTSM::fdc(datbcfac602$flowby)
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


fdc(cbind(datbcfac401$Qnatural, datbcfac401$Qintake))

datbcfac602 <- om_get_rundata(247415, 602, site = omsite)
datbcfac6012 <- om_get_rundata(247415, 6012, site = omsite)
datbcfac6013 <- om_get_rundata(247415, 6013, site = omsite)
om_ts_diff(datbcfac6012, datbcfac6013, "reservoir_use_remain_mg", "reservoir_use_remain_mg")

