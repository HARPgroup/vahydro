# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))


elid = 207925
run.id = 11
cbp6_link <- paste0(github_link, "/cbp6/code");
source(paste0(cbp6_link,"/cbp6_functions.R"))
source(paste(cbp6_link, "/fn_vahydro-1.0.R", sep = ''))

dat <- fn_get_runfile(elid, run.id, site = omsite,  cached = TRUE);
syear = min(dat$year)
eyear = max(dat$year)
if (syear != eyear) {
  sdate <- as.Date(paste0(syear,"-10-01"))
  edate <- as.Date(paste0(eyear,"-09-30"))
} else {
  sdate <- as.Date(paste0(syear,"-02-01"))
  edate <- as.Date(paste0(eyear,"-12-31"))
}
dat <- window(dat, start = sdate, end = edate);
# Filter out when natevap is zero
dat <- dat[dat$whtf_natevap_mgd > 0]

quantile(as.numeric(dat$whtf_natevap_mgd))
quantile(as.numeric(dat$whtf_evap12_mgd))
quantile(as.numeric(dat$whtf_evap123_mgd))

#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
quadratic_model <- lm(
  as.numeric(dat$whtf_evap12_mgd) ~ as.numeric(dat$whtf_natevap_mgd) + I(as.numeric(dat$whtf_natevap_mgd)^2)
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model)

quadratic_model2 <- lm(
  as.numeric(dat$whtf_evap123_mgd) ~ as.numeric(dat$whtf_natevap_mgd) + I(as.numeric(dat$whtf_natevap_mgd)^2)
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model2)

plot(dat$whtf_natevap_mgd, dat$whtf_evap12_mgd, ylim=c(0,110))
points(dat$whtf_natevap_mgd, dat$whtf_evap123_mgd, col='orange')


breg <- lm(as.numeric(dat$whtf_evap12_mgd) ~ as.numeric(dat$et_in))

plot(dat$et_in, dat$whtf_evap12_mgd, ylim=c(0,110))
abline(breg)
loess.smooth(
  x, y, span = 2/3, degree = 1,
  family = c("symmetric", "gaussian"),
  evaluation = 50
)
lines(dat$et_in, dat$whtf_natevap_mgd)
# add quatratic function to the plot
order_id <- order(dat$whtf_natevap_mgd)
lines(x = as.numeric(dat$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model))[order_id],
      col = "red", 
      lwd = 2) 
lines(x = as.numeric(dat$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model2))[order_id],
      col = "purple", 
      lwd = 2) 
summary(breg)

boxplot( as.numeric(dat$wd12_mgd) ~ dat$month)


elid = 207925
omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
amn <- 10.0 * mean(as.numeric(dat$Qin))

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(evap_mgd) as evap_mgd, avg(whtf_reg_mgd) as whtf_reg_mgd from datdf group by month")
anndat <- sqldf("select avg(evap_mgd) as evap_mgd, avg(whtf_reg_mgd) as whtf_reg_mgd from datdf")

mot <- t(as.matrix(modat[,c('evap_mgd', 'whtf_reg_mgd')]) )
mode(mot) <- 'numeric'
barplot(
  mot,
  main="Monthly Mean Evap",
  xlab="Month", 
  col=c("darkblue","darkgreen"),
  legend = c(
    paste('Natural Evap',round(anndat$evap_mgd,1)), 
    paste('WHTF Extra',round(anndat$whtf_reg_mgd,1))
  ), beside=TRUE
)
