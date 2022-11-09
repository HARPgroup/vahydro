library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

################################################################################################
# LOAD FACILITY MODEL RUN DATA:
################################################################################################
#FULL RUNS (84-05)
datbcfac400 <- om_get_rundata(247415, 400, site = omsite)
datbcfac600 <- om_get_rundata(247415, 600, site = omsite)
datbcfac2 <- om_get_rundata(247415, 2, site = omsite)
################################################################################################

################################################################################################
# GENERATE PLOTS:
################################################################################################
dev.off()
export_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/vahydro/R/examples/"
# batch_list <- list(list(runid = 4011,dat = datbcfac4011,legend_text = "Flow (Total Permitted)"),
#                    list(runid = 6011,dat = datbcfac6011,legend_text = "Flow (2.7 mgd & 90% Flow-by)"),
#                    list(runid = 6012,dat = datbcfac6012,legend_text = "Flow (3.2 mgd & 50% Flow-by)")
#                   )
batch_list <- list(list(runid = 400,dat = datbcfac400,legend_text = "Flow (Total Permitted)"),
                   list(runid = 600,dat = datbcfac600,legend_text = "Flow (2.6 mgd & 40% Flow-by)"),
                   list(runid = 2,dat = datbcfac2,legend_text = "Flow (Current Reported Use)")
)
#i <- 1
for (i in 1:length(batch_list)) {
  runid_i <- batch_list[[i]]$runid
  dat_i <- batch_list[[i]]$dat
  legend_text_i <- batch_list[[i]]$legend_text
 
  # FLOW DURATION CURVE PLOTS ---------------------------------------------------
  png(file=paste(export_path,"fdc_",runid_i,".png",sep=""),width=560, height=400)
  hydroTSM::fdc(
    cbind(dat_i$Qnatural, dat_i$Qintake),
    yat = c(1,5,10,25,100,400),
    leg.txt = c("Flow (Natural)",legend_text_i),
    ylab = "Q, [cfs]",
    ylim=c(0, 500)
  )
  dev.off()
  
  # HYDROGRAPH PLOTS ------------------------------------------------------------
  dat_i <- data.frame(dat_i)
  dat_i <- cbind("date" = rownames(dat_i),dat_i)
 
    # DROUGHT PERIOD PLOT 
      # REGULAR Y-AXIS ------------------------------------------------------------
      xmn <- as.Date('1999-01-01')
      xmx <- as.Date('1999-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_i$Qnatural)~as.Date(dat_i$date),type = "l", lty=2, lwd = 1,
           ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(dat_i$Qintake)~as.Date(dat_i$date),type = "l",col='brown3', lwd = 2, 
           axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      # LOG Y-AXIS ------------------------------------------------------------
      xmn <- as.Date('1999-01-01')
      xmx <- as.Date('1999-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,"_log.png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_i$Qnatural)~as.Date(dat_i$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
           #ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(dat_i$Qintake)~as.Date(dat_i$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
           #axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      
      
    # WET PERIOD PLOT
      # REGULAR Y-AXIS ------------------------------------------------------------
      xmn <- as.Date('2003-01-01')
      xmx <- as.Date('2003-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_i$Qnatural)~as.Date(dat_i$date),type = "l", lty=2, lwd = 1,
           ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(dat_i$Qintake)~as.Date(dat_i$date),type = "l",col='brown3', lwd = 2, axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      # LOG Y-AXIS ------------------------------------------------------------ 
      xmn <- as.Date('2003-01-01')
      xmx <- as.Date('2003-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,"_log.png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_i$Qnatural)~as.Date(dat_i$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
           #ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(dat_i$Qintake)~as.Date(dat_i$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
           #axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
}
################################################################################################



################################################################################################
################################################################################################
# NUMBER OF DAYS STORAGE IS BELOW 50%
maxcapacity <- 1941.47
capaity50pct <- maxcapacity*0.5

#400
fac_dat_400 <- om_get_rundata(247415, 4011, site = omsite) 
bc_dat_400 <- om_get_rundata(352078, 4011, site = omsite) 
bc_dat_400 <- om_get_rundata(352078, 4011, site = omsite) 
rseg_bc_dat_400_df <- data.frame(bc_dat_400)

imp_qa_400 <- sqldf(paste("select year,month,day, impoundment_Storage
                 from 'rseg_bc_dat_400_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
length(imp_qa_400$impoundment_Storage)

#600
rseg_bc_dat_600 <- om_get_rundata(352078, 600, site = omsite) 
rseg_bc_dat_600_df <- data.frame(rseg_bc_dat_600)

imp_qa_600 <- sqldf(paste("select year,month,day, impoundment_Storage
                 from 'rseg_bc_dat_600_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
length(imp_qa_600$impoundment_Storage)

#2
rseg_bc_dat_2 <- om_get_rundata(352078, 2, site = omsite) 
rseg_bc_dat_2_df <- data.frame(rseg_bc_dat_2)

imp_qa_2 <- sqldf(paste("select year,month,day, impoundment_Storage
                 from 'rseg_bc_dat_2_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
length(imp_qa_2$impoundment_Storage)
################################################################################################
################################################################################################



################################################################################################
# QA 10/13/21
################################################################################################

# fac_dat_df <- data.frame(datbcfac400)
# #fac_dat_df <- data.frame(datbcfac600)
# 
# # fac_qa <- sqldf("select year,month,day, wd_mgd, discharge_mgd, consumption
# #                  from 'fac_dat_df' WHERE year = 1999 AND month = 1")
# fac_qa <- sqldf("select year,month,day, wd_mgd, discharge_mgd, consumption
#                  from 'fac_dat_df'")
# 
# quantile(fac_dat_df$consumption, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
