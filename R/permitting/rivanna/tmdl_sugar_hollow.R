# Moormans
# Sugar
datsh <- om_get_rundata(337718,11,site=omsite)
dat <-  om_get_rundata(337718,11,site=omsite)

dat$storage_pct <- dat$impoundment_use_remain_mg * 3.07 / dat$impoundment_max_usable
#
storage_pct <- mean(as.numeric(dat$storage_pct) )
if (is.na(storage_pct)) {
  usable_pct_p0 <- 0
  usable_pct_p10 <- 0
  usable_pct_p50 <- 0
} else {
  usable_pcts = quantile(as.numeric(dat$storage_pct), c(0,0.1,0.5) )
  usable_pct_p0 <- usable_pcts["0%"]
  usable_pct_p10 <- usable_pcts["10%"]
  usable_pct_p50 <- usable_pcts["50%"]
}
impoundment_days_remaining <- mean(as.numeric(dat$impoundment_days_remaining) )
if (is.na(impoundment_days_remaining)) {
  remaining_days_p0 <- 0
  remaining_days_p10 <- 0
  remaining_days_p50 <- 0
} else {
  remaining_days = quantile(as.numeric(dat$impoundment_days_remaining), c(0,0.1,0.5) )
  remaining_days_p0 <- remaining_days["0%"]
  remaining_days_p10 <- remaining_days["10%"]
  remaining_days_p50 <- remaining_days["50%"]
}

# this has an impoundment.  Plot it up.
# Now zoom in on critical drought period
pdstart = as.Date(paste0(2008,"-07-01") )
pdend = as.Date(paste0(2009, "-03-31") )
datpd <- window(
  dat,
  start = pdstart,
  end = pdend
);

ymn <- 1
ymx <- 100
par(mar = c(8.8,5,0.5,5))
plot(
  datpd$storage_pct * 100.0,
  ylim=c(ymn,ymx),
  ylab="Reservoir Storage (%)",
  xlab=paste("Lowest 90 Day Flow Period",pdstart,"to",pdend),
  legend=c('Storage', 'Qin', 'Qout', 'Demand (mgd)')
)
par(new = TRUE)
plot(datpd$impoundment_Qin,col='blue', axes=FALSE, xlab="", ylab="")
lines(datpd$impoundment_Qout,col='green')
lines(datpd$impoundment_demand * 1.547,col='red')
axis(side = 4)
mtext(side = 4, line = 3, 'Flow/Demand (cfs)')
