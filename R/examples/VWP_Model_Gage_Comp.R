library(pander);
library(httr);
library(hydroTSM);
library(zoo);
library(hydrotools);
library(plotly);
# save_directory <- "/var/www/html/files/fe/plots"
# save_directory <- "/Users/jklei/Desktop/GitHub/plots"
#save_directory <- "/Users/jklei/Desktop/Big Stone Gap WTP"
save_directory <- "/Users/nrf46657/Desktop/VAHydro Development/GitHub/plots"
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
omsite = site

# Load Libraries
basepath='/var/www/R';
source('/var/www/R/config.R');
options(timeout=1200); # set timeout to twice default level to avoid abort due to high traffic

################################################################################################
rseg.elid = 352078     #Riverseg Model: South Fork Powell River - Big Cherry Reservoir
#fac.elid = 247415      #Facility:Riverseg Model: BIG STONE GAP WTP:Powell River
runid = 401
################################################################################################

################################################################################################
# Riverseg MODEL:
################################################################################################
rseg.info <- fn_get_runfile_info(rseg.elid,runid)
rseg.name <- print(rseg.info$elemname)

# RETRIEVE DATA --------------------------------------------------------------------------------
rseg.dat <- om_get_rundata(rseg.elid,runid) #automatically cuts out model warm-up periods 
rseg.dat.df <- data.frame(rseg.dat)
rseg.dat.df <- cbind("date" = rownames(rseg.dat.df),rseg.dat.df) #CONVERT ROW NAMES TO DATE COLUMN
################################################################################################
# USGS GAGE ####################################################################################
################################################################################################
source(paste(github_location,"/hydro-tools/USGS/usgs_gage_functions.R",sep=""));

#USGS 03529500 POWELL RIVER AT BIG STONE GAP, VA: Drainage area: 112 square miles (36.86898536, -82.7754387)
# NO DATA 1981-09-29 to 2001-10-01
#USGS 03531500 POWELL RIVER NEAR JONESVILLE, VA: Drainage area: 319 square miles (36.66203367, -83.0948928)
gageid <- "03529500"
gage.ts <- streamgage_historic(gageid)
gage.ts <- clean_historic(gage.ts)
#gage.pct <- gage_pct_mo("03529500")

# NEED TO AREA WEIGHT GAGE FLOW TO WITHDRAWAL LOCATION
# SOUTH FORK POWELL RIVER Intake DA = 8.182 square miles (From containing nhdplus segment)
gage.ts$Flow_Adj <- (8.182/112)*gage.ts$Flow
#-----------------------------------------------------------------------------------------------

#png(paste(save_directory,"/rseg_Qout_GAGE_",rseg.elid,"_",runid,".png",sep=""))
png(paste(save_directory,"/rseg_Qout_GAGE_",gageid,"_",rseg.elid,"_",runid,".png",sep=""), width = 1000, height = 600)

ymn <- 0
ymx <- 50
# xmn <- as.Date('2001-06-01')
# xmx <- as.Date('2001-11-15')
xmn <- as.Date('1998-10-01')
###xmn <- as.Date('2001-10-01')
xmx <- as.Date('2002-9-30')
par(mar = c(5,5,2,5))

plot(as.numeric(rseg.dat.df$Qout)~as.Date(rseg.dat.df$date),type = "l",
     col = 'blue',
     #log="y",
     ylim=c(ymn,ymx),xlim=c(xmn,xmx),
     ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx),
     main=paste(rseg.name," (elid: ",rseg.elid,"; runid: ",runid,")",sep="")
     )
lines(as.numeric(gage.ts$Flow_Adj)~as.Date(gage.ts$Date), pch=22, lty=2, col="red")
legend(xmn,ymx,legend=c("Qout","USGS 03529500 POWELL RIVER AT BIG STONE GAP, VA"),
       col=c("blue","red"), lty=c(1,2), cex=c(1,1))
dev.off()
################################################################################################
################################################################################################
################################################################################################

