library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
site <- "http://deq1.bse.vt.edu:81"

export_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/vahydro/R/permitting/Route 58/"
################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 352147 
fac_om_id <- 352155

################################################################################################
# # GENERATE PERCENTILE TABLES
# rseg_dat_all_intakes <- om_get_rundata(rseg_om_id, 600, site = site)
# rseg_dat_intake_1 <- om_get_rundata(rseg_om_id, 6001, site = site)
# rseg_dat_intake_2 <- om_get_rundata(rseg_om_id, 6002, site = site)
# rseg_dat_intake_3 <- om_get_rundata(rseg_om_id, 6015, site = site)
# 
# round(quantile(rseg_dat_all_intakes$Qlocal, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0)),3)  
# round(quantile(rseg_dat_all_intakes$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0)),3)
# round(quantile(rseg_dat_intake_1$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0)),3)
# round(quantile(rseg_dat_intake_2$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0)),3)
# round(quantile(rseg_dat_intake_3$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0)),3)
################################################################################################
################################################################################################

################################################################################################
# GENERATE PLOTS:
################################################################################################
dev.off()
batch_list <- list(list(runid = 600,legend_text = "Max Pumping - All Intakes"),
                   list(runid = 6001,legend_text = "Max Pumping - Intake 1"),
                   list(runid = 6002,legend_text = "Max Pumping - Intake 2"),
                   list(runid = 6015,legend_text = "Max Pumping - Intake 3")
                   )
#i <- 1
for (i in 1:length(batch_list)) {
  runid_i <- batch_list[[i]]$runid
  legend_text_i <- batch_list[[i]]$legend_text
  
  ################################################################################################
  # RETRIEVE RSEG AND FAC DATA, JOIN INTO ONE TABLE
  rseg_dat <- om_get_rundata(rseg_om_id, runid_i, site = omsite) 
  rseg_df <- data.frame(rseg_dat)
  rseg_df <- cbind("date" = rownames(rseg_df),rseg_df)
  dat_join <- rseg_df

  # FLOW DURATION CURVE PLOTS ---------------------------------------------------
  png(file=paste(export_path,"fdc_",runid_i,".png",sep=""),width=560, height=450)
  hydroTSM::fdc(
    cbind(dat_join$Qlocal, dat_join$Qout),
    yat = c(0.10,1,5,10,25,100,400),
    leg.txt = c("Flow (Natural)",paste("Flow (",legend_text_i,")",sep="")),
    ylab = "Q, [cfs]",
    ylim=c(0, 600)
  )
  dev.off()

      # DROUGHT PERIOD PLOT 
      xmn <- as.Date('2001-01-01')
      xmx <- as.Date('2001-12-31')
      # xmn <- as.Date('1985-01-01')
      # xmx <- as.Date('2005-12-31')
      png(paste(export_path,"/hydrograph_Qlocal_Qout_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 50
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_join$Qlocal)~as.Date(dat_join$date),type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx), ylim=c(ymn,ymx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
           #points(as.numeric(dat_join$Qlocal)~as.Date(dat_join$date), pch = 19, col = "black")
      par(new = TRUE)
      plot(as.numeric(dat_join$Qout)~as.Date(dat_join$date),type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx), ylim=c(ymn,ymx),ylab="",xlab="")
           #points(as.numeric(dat_join$Qout)~as.Date(dat_join$date), pch = 19, col = "brown3")
      legend("topright",legend=c("Flow (Natural)",paste("Flow (",legend_text_i,")",sep="")),col=c("black","brown3"), 
             lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      
      # WET PERIOD PLOT
      xmn <- as.Date('2003-01-01')
      xmx <- as.Date('2003-12-31')
      png(paste(export_path,"/hydrograph_Qlocal_Qout_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 50
      par(mar = c(5,5,2,5))
      plot(as.numeric(dat_join$Qlocal)~as.Date(dat_join$date),type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx), ylim=c(ymn,ymx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(dat_join$Qout)~as.Date(dat_join$date),type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx), ylim=c(ymn,ymx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",paste("Flow (",legend_text_i,")",sep="")),col=c("black","brown3"), 
             lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
}
################################################################################################
################################################################################################
################################################################################################
