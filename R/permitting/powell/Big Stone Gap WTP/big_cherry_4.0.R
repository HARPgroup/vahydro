library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 352123 #South Fork Powell River - Below Big Cherry Reservoir
fac_om_id <- 247415 #BIG STONE GAP WTP:Powell River
################################################################################################
# GENERATE PLOTS:
################################################################################################
dev.off()
export_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/vahydro/R/permitting/Big Stone Gap WTP/"
batch_list <- list(list(runid = 400,legend_text = "Flow (Total Permitted)"),
                   list(runid = 600,legend_text = "Flow (2.6 mgd & 40% Flow-by)"),
                   list(runid = 2,legend_text = "Flow (Current Reported Use)")
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
  
  fac_dat <- om_get_rundata(fac_om_id, runid_i, site = omsite)
  fac_df <- data.frame(fac_dat)
  fac_df <- cbind("date" = rownames(fac_df),fac_df)
  
  dat_join <- sqldf(
    paste(
      "SELECT *
    FROM rseg_df AS a
    LEFT OUTER JOIN fac_df AS b
    ON a.date = b.date")
  )
  ################################################################################################
  
  # FLOW DURATION CURVE PLOTS ---------------------------------------------------
  png(file=paste(export_path,"fdc_",runid_i,".png",sep=""),width=560, height=450)
  hydroTSM::fdc(
    cbind(dat_join$Qnatural, dat_join$Qout),
    yat = c(0.10,1,5,10,25,100,400),
    leg.txt = c("Flow (Natural)",legend_text_i),
    ylab = "Q, [cfs]",
    ylim=c(0.01, 500)
  )
  dev.off()
  
    # DROUGHT PERIOD PLOT 
      # REGULAR Y-AXIS ------------------------------------------------------------
      xmn <- as.Date('1999-01-01')
      xmx <- as.Date('1999-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(fac_df$Qnatural)~as.Date(fac_df$date),type = "l", lty=2, lwd = 1,
           ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(fac_df$Qintake)~as.Date(fac_df$date),type = "l",col='brown3', lwd = 2, 
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
      plot(as.numeric(fac_df$Qnatural)~as.Date(fac_df$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(fac_df$Qintake)~as.Date(fac_df$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
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
      plot(as.numeric(fac_df$Qnatural)~as.Date(fac_df$date),type = "l", lty=2, lwd = 1,
           ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(fac_df$Qintake)~as.Date(fac_df$date),type = "l",col='brown3', lwd = 2, axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      # LOG Y-AXIS ------------------------------------------------------------ 
      xmn <- as.Date('2003-01-01')
      xmx <- as.Date('2003-12-31')
      png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,"_log.png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(fac_df$Qnatural)~as.Date(fac_df$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(fac_df$Qintake)~as.Date(fac_df$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
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
rseg_bc_dat_400 <- om_get_rundata(352078, 400, site = omsite) 
rseg_bc_dat_400_df <- data.frame(rseg_bc_dat_400)

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

