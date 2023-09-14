basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')

elid = 257221 #Rappahannock River @ Fall Line RU5_6030_0001
gage_number = '01667500' # Rapidan
startdate <- "1984-10-01"
enddate <- "2020-09-30"
pstartdate <- "2008-04-01"
penddate <- "2008-11-30"

rmarkdown::render('C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd',
                  output_file ='C:/Workspace/modeling/projects/rappahannock/wilderness/te_wilderness_v05',
                  params = list(doc_title = "VWP CIA Summary - Wilderness WTP",
                                rseg.hydroid = 68230,
                                fac.hydroid = 73075,
                                runid.list = c("runid_400", "runid600", "runid_6001"),
                                rseg.metric.list = c("Qout","l30_Qout","l90_Qout","consumptive_use_frac","wd_cumulative_mgd","ps_cumulative_mgd","wd_mgd","ps_mgd"),
                                intake_stats_runid = 6001,
                                preferred_runid = "runid_6001",
                                upstream_rseg_ids=c(68127,67706,68371,68140,68227,68226),
                                users_metric = "base_demand_mgy"
                  )
)


# Get the VAHydro/CBP6 Model
# runid:
# 1131 = hourly, 1998-2002
runid = 400
model_data <- om_get_rundata(elid, runid, site=omsite)

# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
om_flow_table(gage_data, 'flow')
available_mgd <- gage_data
available_mgd$available_mgd <- (available_mgd$flow * 0.05) / 1.547
avail_table = om_flow_table(available_mgd, 'available_mgd')
kable(avail_table, 'markdown')

#limit to hourly model period
hstart <- min(index(hdat))
hend <- max(index(hdat))
gagehdat <- window(gage_data, start = hstart, end = hend)


dat2 = list()
dat2$vahydro <- model_data$Qout
dat2$usgs <- gage_data$flow
dat2 <- as.data.frame(dat2)
datlow <- sqldf("select * from dat2 where usgs <= 50")
lm2 <- lm(
  datlow$usgs ~ I(datlow$vahydro)
)
summary(lm2)
quantile(datlow$vahydro)
quantile(datlow$usgs)

dat2$vreg <- (-31.645 + (0.795360 * dat2$vahydro))
dat2$vreg[which(dat2$vreg <0)] <- 0
quantile(dat2$vreg)
quantile(dat2$usgs)
mean(dat2$usgs)
mean(dat2$vahydro)
qmax <- max(max(dat2$usgs), max(dat2$vahydro))
plot(
  dat2$vahydro ~
    dat2$usgs,
    ylim = c(0,qmax)
)
#points(dat2$vreg ~ dat2$vahydro, col="red")
points(dat2$vreg ~ dat2$usgs, col="purple")
qprobs <- c(0,0.1,0.25,0.35,0.5,0.6,0.75,1.0)
qtable_comp <- rbind(
  round(quantile(dat2$vahydro, probs=qprobs)),
  round(quantile(dat2$usgs, probs=qprobs)),
  round(quantile(dat2$vreg, probs=qprobs))
)
kable(qtable_comp, 'markdown')


ymx <- max(c(max(dat2$vreg),max(dat2$usgs)))
plot(
  dat2$vreg, ylim = c(0,ymx),
  ylab="Flow/WD/PS (cfs)",
  xlab=paste("Model vs USGS",hstart,"to",hend),
  main=paste("1Hr2Daily Timestep, L90:",l90_husgs,"(u)",l90_hmodel,"(m)"),
)
lines(dat2$usgs, col='blue')

hydroTSM::fdc(dat2)


# test flowbys, demand, and storage remaining
datrpr41$flowby_current
df41 <- as.data.frame(datrpr41)
df41common <- dat2[32:nrow(dat2),]
datall <- cbind(df41, df41common)
write.table(datall,file="/Workspace/tmp/rpr.csv")

