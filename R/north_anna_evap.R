# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))


# NA Dam/Lake: 207925, Bechtel model: 279185, WS outlet: 207923
# meteorology: 207959
elid = 207925; 

run.id = 101
#cbp6_link <- paste0(github_link, "/cbp6/code");
#source(paste0(cbp6_link,"/cbp6_functions.R"))
#source(paste(cbp6_link, "/fn_vahydro-1.0.R", sep = ''))

bechtel <- fn_get_runfile(elid, run.id, site = omsite,  cached = FALSE);
bechtel$whtf_natevap_mgd <- (bechtel$et_in * 0.62473 * bechtel$lake_area / 12.0) / 3.07

bechtel$whtf_natevap_mgd = (as.numeric(bechtel$et_in) * 0.62473 * 13000 / 12.0) / 3.07
quadratic_model <- lm(
  as.numeric(bechtel$whtf_evap12_mgd) ~ as.numeric(bechtel$whtf_natevap_mgd) + I(as.numeric(bechtel$whtf_natevap_mgd)^2)
)
#bechtel$whtf_natevap_mgd = (as.numeric(bechtel$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model)
quadratic_model123 <- lm(
  as.numeric(bechtel$whtf_evap123_mgd) ~ as.numeric(bechtel$whtf_natevap_mgd) + I(as.numeric(bechtel$whtf_natevap_mgd)^2)
)
summary(quadratic_model123)

breg <- lm(as.numeric(bechtel$whtf_evap12_mgd) ~ as.numeric(bechtel$et_in))

plot(bechtel$et_in, bechtel$whtf_evap12_mgd, ylim=c(0,110))
abline(breg)
loess.smooth(
  x, y, span = 2/3, degree = 1,
  family = c("symmetric", "gaussian"),
  evaluation = 50
)
lines(bechtel$et_in, bechtel$whtf_natevap_mgd)
points(bechtel$et_in, bechtel$whtf_evap123_mgd, col = 'purple')
# add quatratic function to the plot
order_id <- order(bechtel$whtf_natevap_mgd)
lines(x = as.numeric(bechtel$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model))[order_id],
      col = "red", 
      lwd = 2) 
lines(x = as.numeric(bechtel$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model123))[order_id],
      col = "green", 
      lwd = 2) 
summary(breg)

boxplot( as.numeric(bechtel$whtf_evap12_mgd) ~ bechtel$month)


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
