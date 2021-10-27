library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
site <- "http://deq1.bse.vt.edu:81"

################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 352147 
fac_om_id <- 352155
#runid <- 601
runid <- 600


rseg.dat <- om_get_rundata(elid=rseg_om_id,runid=runid,site=site) #automatically cuts out model warm-up periods
rseg.dat.df <- data.frame(rseg.dat)

quantile(rseg.dat.df$local_channel_Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

rseg_qa <- sqldf("select year,month,day, local_channel_Qout, Qlocal, Qreach, Qout
                 from 'rseg.dat.df' WHERE year = 2001 AND month = 11")

rseg.dat.df$Qnatural
rseg.dat.df$Qout
colnames(rseg.dat.df)

fac.dat <- om_get_rundata(elid=fac_om_id,runid=runid,site=site) #automatically cuts out model warm-up periods
fac.dat.df <- data.frame(fac.dat)

fac_qa <- sqldf("select year,month,day, wd_mgd, available_mgd, Qintake, flowby_proposed
                 from 'fac.dat.df' ")
                 #from 'fac.dat.df' WHERE year = 2001 AND month = 11")

quantile(fac.dat.df$wd_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))







################################################################################################
# GENERATE PLOTS:
################################################################################################
dev.off()
export_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/vahydro/R/permitting/Route 58/"
batch_list <- list(list(runid = 600,legend_text = "test run")
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
  
  # fac_dat <- om_get_rundata(fac_om_id, runid_i, site = omsite)
  # fac_df <- data.frame(fac_dat)
  # fac_df <- cbind("date" = rownames(fac_df),fac_df)
  # 
  # dat_join <- sqldf(
  #   paste(
  #     "SELECT *
  #   FROM rseg_df AS a
  #   LEFT OUTER JOIN fac_df AS b
  #   ON a.date = b.date")
  # )
  dat_join <- rseg_df
  ################################################################################################
  
  # FLOW DURATION CURVE PLOTS ---------------------------------------------------
  png(file=paste(export_path,"fdc_",runid_i,".png",sep=""),width=560, height=450)
  hydroTSM::fdc(
    cbind(dat_join$Qlocal, dat_join$Qout),
    #cbind(dat_join$Qnatural, dat_join$Qout),
    yat = c(0.10,1,5,10,25,100,400),
    leg.txt = c("Qlocal","Qout"),
    ylab = "Q, [cfs]",
    ylim=c(0, 600)
  )
  dev.off()
  
  #quantile(dat_join$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
  
  
    # DROUGHT PERIOD PLOT 
      # # REGULAR Y-AXIS ------------------------------------------------------------
      # #xmn <- as.Date('1999-01-01')
      # #xmx <- as.Date('1999-12-31')
      # xmn <- as.Date('2001-01-01')
      # xmx <- as.Date('2001-12-31')
      # png(paste(export_path,"/hydrograph_Qreach_Qout_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      # #png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      # ymn <- 0
      # ymx <- 110
      # par(mar = c(5,5,2,5))
      # plot(as.numeric(fac_df$Qreach)~as.Date(fac_df$date),type = "l", lty=2, lwd = 1,
      #      ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      # par(new = TRUE)
      # plot(as.numeric(fac_df$Qout)~as.Date(fac_df$date),type = "l",col='brown3', lwd = 2, 
      #      axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      # legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      # dev.off()
      # LOG Y-AXIS ------------------------------------------------------------
      xmn <- as.Date('2001-01-01')
      xmx <- as.Date('2001-12-31')
      png(paste(export_path,"/hydrograph_Qlocal_Qout_",xmn,"_",xmx,"_",runid_i,"_log.png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(rseg_df$Qlocal)~as.Date(rseg_df$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(rseg_df$Qout)~as.Date(rseg_df$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Qlocal","Qout"),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
      
      
    # WET PERIOD PLOT
      # # REGULAR Y-AXIS ------------------------------------------------------------
      # xmn <- as.Date('2003-01-01')
      # xmx <- as.Date('2003-12-31')
      # png(paste(export_path,"/hydrograph_Qnatural_Qintake_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
      # ymn <- 0
      # ymx <- 110
      # par(mar = c(5,5,2,5))
      # plot(as.numeric(fac_df$Qnatural)~as.Date(fac_df$date),type = "l", lty=2, lwd = 1,
      #      ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      # par(new = TRUE)
      # plot(as.numeric(fac_df$Qintake)~as.Date(fac_df$date),type = "l",col='brown3', lwd = 2, axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")
      # legend("topright",legend=c("Flow (Natural)",legend_text_i),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      # dev.off()
      # LOG Y-AXIS ------------------------------------------------------------ 
      xmn <- as.Date('2003-01-01')
      xmx <- as.Date('2003-12-31')
      png(paste(export_path,"/hydrograph_Qlocal_Qout_",xmn,"_",xmx,"_",runid_i,"_log.png",sep=""), width = 1100, height = 600)
      ymn <- 0
      ymx <- 110
      par(mar = c(5,5,2,5))
      plot(as.numeric(rseg_df$Qlocal)~as.Date(rseg_df$date), log="y",type = "l", lty=2, lwd = 1,
           xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
      par(new = TRUE)
      plot(as.numeric(rseg_df$Qout)~as.Date(rseg_df$date), log="y",type = "l",col='brown3', lwd = 2, 
           axes=FALSE,xlim=c(xmn,xmx),ylab="",xlab="")
      legend("topright",legend=c("Qlocal","Qout"),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
      dev.off()
}
################################################################################################



################################################################################################
################################################################################################
# # NUMBER OF DAYS STORAGE IS BELOW 50%
# maxcapacity <- 1941.47
# capaity50pct <- maxcapacity*0.5
# 
# #400
# rseg_bc_dat_400 <- om_get_rundata(352078, 400, site = omsite) 
# rseg_bc_dat_400_df <- data.frame(rseg_bc_dat_400)
# 
# imp_qa_400 <- sqldf(paste("select year,month,day, impoundment_Storage
#                  from 'rseg_bc_dat_400_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
# length(imp_qa_400$impoundment_Storage)
# 
# #600
# rseg_bc_dat_600 <- om_get_rundata(352078, 600, site = omsite) 
# rseg_bc_dat_600_df <- data.frame(rseg_bc_dat_600)
# 
# imp_qa_600 <- sqldf(paste("select year,month,day, impoundment_Storage
#                  from 'rseg_bc_dat_600_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
# length(imp_qa_600$impoundment_Storage)
# 
# #2
# rseg_bc_dat_2 <- om_get_rundata(352078, 2, site = omsite) 
# rseg_bc_dat_2_df <- data.frame(rseg_bc_dat_2)
# 
# imp_qa_2 <- sqldf(paste("select year,month,day, impoundment_Storage
#                  from 'rseg_bc_dat_2_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
# length(imp_qa_2$impoundment_Storage)
################################################################################################
################################################################################################

