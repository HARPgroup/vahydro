library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

################################################################################################
# LOAD FACILITY MODEL RUN DATA:
################################################################################################
#FULL RUNS (84-05)
datbcfac400 <- om_get_rundata(247415, 402, site = omsite)
datbcfac600 <- om_get_rundata(247415, 600, site = omsite)
datbcfac2 <- om_get_rundata(247415, 2, site = omsite)

datsfp4 <- om_get_rundata(352123 , 4011, site = omsite)
quantile(datsfp4$Qout)
quantile(datsfp4$ps_mgd)

runid = 6011
datsfp <- om_get_rundata(352123 , runid, site = omsite)
datsfp$Qlocal_below_bc
datsfp$Qnatural <- (8.2/2.66)*datsfp$Qlocal_below_bc
quantile(datsfp$Qnatural)
quantile(datsfp$Qout)
hydroTSM::fdc(
  cbind(datsfp$Qnatural, datsfp$Qout),
  ylim=c(0.001,1000)
)

quantile(datsfp4$Qlocal + datsfp4$Qtrib - (1.547*datsfp4$child_wd_mgd))
quantile(datsfp4$local_channel_Qin)
quantile(datsfp4$local_channel_Qout)
quantile(datsfp4$Qlocal_below_bc)


datbcfac400[243:245,c('max_mgd','available_mgd','adj_demand_mgd', 'base_demand_mgd', 'unmet_demand_mgd', 'wd_mgd')]
datsfp4[263:315,c('local_channel_Qin', 'local_channel_Qout', 'child_wd_mgd', 'Qtrib', 'Qlocal')]

datsfp4$Qrem <- datsfp4$local_channel_Qin - datsfp4$child_wd_mgd * 1.547 
datsfp4[which(datsfp4$local_channel_Qout < 0.5),c('local_channel_Qin', 'local_channel_Qout', 'child_wd_mgd', 'Qrem')]
datsfp4[263:315,c('local_channel_Qin', 'Qlocal', 'local_channel_Qout', 'child_wd_mgd', 'Qrem')]

datbc4 <- om_get_rundata(352078 , 4011, site = omsite)
datbc4$Qoughttab <- datbc4$impoundment_Qout + datbc4$Qlocal_below_bc - datbc4$ps_refill_pump_mgd * 1.547
datbc4$Qoughttab2 <- datbc4$release + datbc4$Qlocal_below_bc - datbc4$ps_refill_pump_mgd * 1.547

datbc4$pump_cfs <- 1.547 * datbc4$ps_refill_pump_mgd
quantile(datbc4$Qoughttab)
quantile(datbc4$Qout)
quantile(datbc4$impoundment_Qout)
quantile(datbc4$release)
quantile(datbc4$Qlocal_below_bc)

# should be?
quantile(datbc4$impoundment_spill + datbc4$release + datbc4$Qlocal_below_bc - 1.547 * datbc4$ps_refill_pump_mgd)
quantile(datbc4$impoundment_spill + datbc4$release)
quantile(datbc4$impoundment_spill + datbc4$impoundment_release)
datbc4[,c("release", "impoundment_release")]

quantile(datbc4$Qout + datbc4$Qlocal_below_bc - 1.547 * datbc4$ps_refill_pump_mgd)

mean(datbc4$impoundment_spill + datbc4$impoundment_release)
quantile(datbc4$impoundment_spill + datbc4$impoundment_release)
quantile(datbc4$impoundment_Qout)
quantile(datbc4$Qout)


datbc4$release_new <- datbc4$child_wd_mgd * 1.547 + datbc4$bc_flowby_cfs - datbc4$Qlocal_below_bc
datbc4[263:315,c('pump_cfs', 'release', 'Qlocal_below_bc')]
datbc6 <- om_get_rundata(352078 , 6011, site = omsite)
datbcfac6 <- om_get_rundata(247415 , 6011, site = omsite)

dfdatbcfac6 <- as.data.frame(datbcfac6)
quantile(datbcfac400$rejected_demand_pct)
quantile(datbcfac400$available_mgd)
quantile(datbcfac400$max_mgd)
quantile(datbcfac400$adj_demand_mgd)
quantile(datbcfac400$base_demand_mgd)
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
