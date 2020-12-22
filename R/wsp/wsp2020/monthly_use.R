#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
source(paste(om_location,'R/summarize','rseg_elfgen.R',sep='/'))
library(stringr)
# dirs/URLs
save_directory <- "/var/www/html/data/proj3/out"
save_url <- paste(str_remove(site, 'd.dh'), "data/proj3/out", sep='');

# Read Args
elid <- 209975  # 209975 James at Richmond, 233551 Midde Potomac at Fall Line
runid <- 11

dat <- om_get_rundata(elid, runid)
datdf <- as.data.frame(dat)
modat <- sqldf(
  "select month, avg(wd_cumulative_mgd) as wd_mgd, 
   avg(ps_cumulative_mgd) as ps_mgd, avg(ps_nextdown_mgd) as ps_nextdown_mgd 
  from datdf group by month
")
modat$ps_total_mgd <- modat$ps_mgd + modat$ps_nextdown_mgd
#barplot(wd_mgd ~ month, data=modat)

awd <- mean(datdf$wd_cumulative_mgd)
modat$unitval <- modat$wd_mgd / awd
modat$psfact <- modat$ps_total_mgd / modat$wd_mgd
modat$vawd <- modat$unitval * 1300
modat$vaps <- modat$psfact * modat$vawd
modat$vawd2040 <- modat$unitval * 1540
modat$vaps2040 <- modat$psfact * modat$vawd2040
modat$cu2020 <- modat$vawd - modat$vaps
modat$cu2040 <- modat$vawd2040 - modat$vaps2040
modat$zero <- 0.0

# Using plot and ploygon with rev() function per http://www.alisonsinclair.ca/2011/03/shading-between-curves-in-r/
par(mar=c(5.1,4.1,4.1,4.1))
cucols=c(rgb(0.2,0.1,0.5,0.9), 'black', rgb(0.2,0.1,0.5,0.2))
plot(
  modat$month,
  modat$vawd, 
  col=rgb(0.2,0.1,0.5,0.9) , 
  type="o" , lwd=3 , xlab="" , ylab="Withdrawal/Point Source (mgd)" , pch=20,
  ylim=c(0,2500),
  main="Monthly Water Use, 2020"
)
lines(
  modat$month,
  modat$vaps, 
  type="o" , lwd=3 , xlab="" , ylab="size" , pch=20,
)
polygon( 
  c(modat$month, rev(modat$month)) , 
  c( modat$vaps, rev(modat$vawd)) , 
  col=rgb(0.2,0.1,0.5,0.2), border=F)

legend(2500, NULL, c('Withdrawal', 'Discharge', 'Consumptive Use'),
       col=cucols, 
       fill=cucols,
      lty=1:2, cex=0.8
)
mean(modat$cu2040)



# Using plot and ploygon with rev() function per http://www.alisonsinclair.ca/2011/03/shading-between-curves-in-r/
par(mar=c(5.1,4.1,4.1,4.1))
cucols=c(rgb(0.307, 0.45, 0.4,0.2), rgb(0.2,0.1,0.5,0.2))
plot(
  modat$month,
  modat$cu2020, 
  col=rgb(0.2,0.1,0.5,0.9) , 
  type="o" , lwd=3 , xlab="" , ylab="Consumptive Use (mgd)" , pch=20,
  ylim=c(0,1000),
  main="Monthly Consumptive Water Use 2020-2040"
)
lines(
  modat$month,
  modat$cu2040, 
  type="o" , lwd=3 , xlab="" , ylab="size" , pch=20,
)
# add shading for 2020 CU
polygon( 
  c(modat$month, rev(modat$month)) , 
  c( modat$zero, rev(modat$cu2020)) , 
  col=rgb(0.307, 0.45, 0.4,0.2), border=F)
# Add shading for 2040 CU
polygon( 
  c(modat$month, rev(modat$month)) , 
  c( modat$cu2020, rev(modat$cu2040)) , 
  col=rgb(0.2,0.1,0.5,0.2), border=F)

legend(1000, NULL, c('Consumptive Use 2020', 'Consumptive Use 2040'),
       col=cucols, 
       fill=cucols,
       lty=1:2, cex=0.8
)
mean(modat$cu2040)

###

# Using plot and ploygon with rev() function per http://www.alisonsinclair.ca/2011/03/shading-between-curves-in-r/
par(mar=c(5.1,4.1,4.1,4.1))
cucols=c(rgb(0.2,0.1,0.5,0.9), 'black', rgb(0.2,0.1,0.5,0.2))
plot(
  modat$month,
  modat$vawd2040, 
  col=rgb(0.2,0.1,0.5,0.9) , 
  type="o" , lwd=3 , xlab="" , ylab="Withdrawal, Point Source (mgd)" , pch=20,
  ylim=c(0,2500),
  main="Monthly Consumptive Surface Water Use, 2020"
)
lines(
  modat$month,
  modat$vaps2040, 
  type="o" , lwd=3 , xlab="" , ylab="size" , pch=20,
)
polygon( 
  c(modat$month, rev(modat$month)) , 
  c( modat$vaps2040, rev(modat$vawd2040)) , 
  col=rgb(0.2,0.1,0.5,0.2), border=F)

legend(2500, NULL, c('WD', 'PS', 'CU'),
       col=cucols, 
       fill=cucols,
       lty=1:2, cex=0.8
)


# Using plot and ploygon with rev() function per http://www.alisonsinclair.ca/2011/03/shading-between-curves-in-r/
par(mar=c(5.1,4.1,4.1,4.1))
cucols=c(rgb(0.2,0.1,0.5,0.9), 'black', rgb(0.2,0.1,0.5,0.2))
plot(
  modat$month,
  modat$cu2040, 
  col=rgb(0.2,0.1,0.5,0.9) , 
  type="o" , lwd=3 , xlab="" , ylab="Withdrawal, Point Source (mgd)" , pch=20,
  ylim=c(0,2500),
  main="Monthly Consumptive Surface Water Use, 2020"
)
lines(
  modat$month,
  modat$cu2040, 
  type="o" , lwd=3 , xlab="" , ylab="size" , pch=20,
)
polygon( 
  c(modat$month, rev(modat$month)) , 
  c( modat$cu2040, modat$zero) , 
  col=rgb(0.2,0.1,0.5,0.2), border=F)

legend(2500, NULL, c('WD', 'PS', 'CU'),
       col=cucols, 
       fill=cucols,
       lty=1:2, cex=0.8
)

# Bungled attempts using ggplot

molist <- sqldf(
  "select month, wd_mgd as value, 'wd' as dgroup from modat
  UNION 
   select month, ps_mgd as value, 'ps' as dgroup from modat
  "
)
awd <- mean(datdf$wd_cumulative_mgd)
molist$unitval <- molist$value / awd
molist$vawd <- molist$unitval * 1300

ggplot(molist, aes(x=month, y=value, fill=dgroup)) + 
  geom_area()

ggplot(molist, aes(x=month, y=vawd, fill=dgroup)) + 
  geom_area(position = "identity")
