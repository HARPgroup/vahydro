library(pander);
library(httr);
library(hydroTSM);
# save_directory <- "/var/www/html/files/fe/plots"
save_directory <- "/Users/jklei/Desktop/GitHub/plots"
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh

# Load Libraries
basepath='/var/www/R';
source('/var/www/R/config.R');
options(timeout=1200); # set timeout to twice default level to avoid abort due to high traffic


# elid = 258595
# runid = 12

elid = 352078 #South Fork Powell River - Big Cherry Reservoir
runid = 601

# GET DATA
omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
dat.df <- data.frame(dat)
# Qout_max <- max(as.numeric(dat$Qout))
# Runit_max <- max(as.numeric(dat$Runit))

# PLOT Qout DATA
png(paste(save_directory,"/rseg_Qout_",elid,"_",runid,".png",sep=""))
boxplot(as.numeric(dat$Qout) ~ dat$year, ylim=c(0,20),
        main=paste("elid: ",elid,"\nrunid: ",runid,sep=""),
        xlab="Date", ylab="Qout (cfs)"  
        )
dev.off()

# PLOT Runit DATA
png(paste(save_directory,"/rseg_Runit_",elid,"_",runid,".png",sep=""))
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,5),
        main=paste("elid: ",elid,"\nrunid: ",runid,sep=""),
        xlab="Date", ylab="Runit (cfs)"  
)
dev.off()





