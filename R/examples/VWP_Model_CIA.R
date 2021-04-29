library(pander);
library(httr);
library(hydroTSM);
library(zoo);
library(hydrotools);
library(plotly);
# save_directory should be set in config.local.private which gets loaded below in config.R
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
omsite = site

# Load Libraries
basepath='/var/www/R';
source('/var/www/R/config.R');
options(timeout=1200); # set timeout to twice default level to avoid abort due to high traffic

################################################################################################
rseg.elid = 352078     #Riverseg Model: South Fork Powell River - Big Cherry Reservoir
fac.elid = 247415      #Facility:Riverseg Model: BIG STONE GAP WTP:Powell River
runid =6012
################################################################################################

################################################################################################
# Riverseg MODEL:
################################################################################################
rseg.info <- fn_get_runfile_info(rseg.elid,runid)
print(rseg.info$elemname)

# RETRIEVE DATA --------------------------------------------------------------------------------
# rseg.dat <- fn_get_runfile(rseg.elid, runid, site= omsite,  cached = FALSE);
# rseg.dat <- window(rseg.dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
rseg.dat <- om_get_rundata(rseg.elid,runid) #automatically cuts out model warm-up periods 
rseg.dat.df <- data.frame(rseg.dat)
write.csv(rseg.dat.df, paste(save_directory,"/rseg.dat.df_",rseg.elid,"_",runid,".csv",sep=""))
# Qout_max <- max(as.numeric(rseg.dat.df$Qout))
# Runit_max <- max(as.numeric(rseg.dat.df$Runit))


################################################################################################
# QA:

# VIEW QUANTILE DATA ---------------------------------------------------------------------------
quantile(rseg.dat.df$bc_release_cfs, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

colnames(rseg.dat.df)

# SQL QA ---------------------------------------------------------------------------------------
rseg_qa <- sqldf("select * from 'rseg.dat.df' where release > impoundment_Qin")

rseg_qa <- sqldf("select year,month,day, release, impoundment_Qin, impoundment_days_remaining 
                 from 'rseg.dat.df' where release > 10")

rseg_qa <- sqldf("select year,month,day, release, impoundment_Qin, impoundment_days_remaining, impoundment_Storage 
                 from 'rseg.dat.df' WHERE year = 2002 AND month = 3")

rseg_qa <- sqldf("select year,month,day, release, impoundment_Qin, impoundment_days_remaining, impoundment_Storage 
                 from 'rseg.dat.df' WHERE release > impoundment_Qin")
################################################################################################


# PLOT DATA ------------------------------------------------------------------------------------
# Qout
png(paste(save_directory,"/rseg_Qout_",rseg.elid,"_",runid,".png",sep=""))
boxplot(as.numeric(rseg.dat$Qout) ~ rseg.dat$year, ylim=c(0,20),
        main=paste("elid: ",rseg.elid,"\nrunid: ",runid,sep=""),
        xlab="Date", ylab="Qout (cfs)"  
        )
dev.off()

# Runit
png(paste(save_directory,"/rseg_Runit_",rseg.elid,"_",runid,".png",sep=""))
boxplot(as.numeric(rseg.dat$Runit) ~ rseg.dat$year, ylim=c(0,20),
        main=paste("elid: ",rseg.elid,"\nrunid: ",runid,sep=""),
        xlab="Date", ylab="Runit (cfs)"  
)
dev.off()
################################################################################################
#CONVERT ROW NAMES TO DATE COLUMN
rseg.dat.df <- cbind("date" = rownames(rseg.dat.df),rseg.dat.df)

png(paste(save_directory,"/rseg_Qout_hydrograph_",rseg.elid,"_",runid,".png",sep=""))
# ymn <- 1
# ymx <- 100
ymn <- 0
ymx <- 20
xmn <- as.Date('2000-06-01')
xmx <- as.Date('2000-11-15')
par(mar = c(5,5,2,5))

plot(as.numeric(rseg.dat.df$Qout)~as.Date(rseg.dat.df$date),type = "l",
     col = 'blue',
     ylim=c(ymn,ymx),xlim=c(xmn,xmx),
     ###ylab="available_mgd (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
     ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx),
     main=paste("elid: ",rseg.elid,"; runid: ",runid,sep=""))

 legend(xmn,ymx,legend=c("Qout"),
        col=c("blue"), lty=1, cex=1)
dev.off()
################################################################################################
################################################################################################
################################################################################################
# FACILITY MODEL:
################################################################################################
fac.info <- fn_get_runfile_info(fac.elid,runid)
print(fac.info$elemname)

# RETRIEVE DATA --------------------------------------------------------------------------------
fac.dat <- fn_get_runfile(fac.elid, runid, site= omsite,  cached = FALSE);
fac.dat <- window(fac.dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
# fac.dat <- om_get_rundata(fac.elid, runid) #automatically cuts out model warm-up periods 
fac.dat.df <- data.frame(fac.dat)

write.csv(fac.dat.df, paste(save_directory,"/fac.dat.df_",fac.elid,"_",runid,".csv",sep=""))

# PLOT DATA ------------------------------------------------------------------------------------
#png(paste(save_directory,"/fac_available_mgd_Qintake_",fac.elid,"_",runid,".png",sep=""), width = 800, height = 500)
png(paste(save_directory,"/fac_available_mgd_Qintake_",fac.elid,"_",runid,".png",sep=""))
# ymn <- 1
# ymx <- 100
ymn <- 0
ymx <- 20
xmn <- as.Date('2000-06-01')
xmx <- as.Date('2000-11-15')
par(mar = c(5,5,2,5))

plot((as.numeric(fac.dat.df$available_mgd) * 1.547)~as.Date(fac.dat.df$thisdate),type = "l",
     ylim=c(ymn,ymx),xlim=c(xmn,xmx),
     ###ylab="available_mgd (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
     ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx),
     main=paste("elid: ",fac.elid,"; runid: ",runid,sep=""))

par(new = TRUE)
# ymx2 <- max(as.numeric(fac.dat.df$Qintake))
# plot(fac.dat.df$Qintake,col='blue', axes=FALSE, xlab="", ylab="",ylim=c(0,ymx2))
plot(as.numeric(fac.dat.df$Qintake)~as.Date(fac.dat.df$thisdate),type = "l",col='blue', axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
###axis(side = 4)
###mtext(side = 4, line = 3, 'Qintake (cfs)')

 legend(xmn,ymx,legend=c("available_mgd", "Qintake"),
        col=c("black", "blue"), lty=1:1, cex=1)

dev.off()


# PLOT DATA (Plotly) -------------------------------------------------------------------------------
#fig <- plot_ly(data = fac.dat.df, x = as.Date(fac.dat.df$thisdate), y = ~(as.numeric(fac.dat.df$available_mgd) * 1.547),type='scatter')


#f2 <- fig %>% add_trace(y = ~as.numeric(fac.dat.df$Qintake), name = 'Qintake',type = 'scatter')
