library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 352123 #South Fork Powell River - Below Big Cherry Reservoir
# rseg_om_id <- 352078 #Big Cherry Reservoir
fac_om_id <- 247415 #BIG STONE GAP WTP:Powell River
################################################################################################
# GENERATE PLOTS:
################################################################################################
# dev.off()
export_path <- "C:/Users/nrf46657/Desktop/VWP Modeling/Big Stone Gap WTP/Nov_2022_Coordination/"

# final runs to be included in TE
batch_list <- list(list(runid = 402,legend_text = "Flow (Total Permitted)"),
                   list(runid = 602,legend_text = "Flow (2.6 mgd & 40% Flow-by)")
                   )

# current conditions run
# batch_list <- list(list(runid = 201,legend_text = "Flow (Current Conditions)"))

# new meteorology runs
# batch_list <- list(list(runid = 4012,legend_text = "Flow (Total Permitted - New Met)"))
# batch_list <- list(list(runid = 6012,legend_text = "Flow (2.6 mgd & 40% Flow-by - New Met)"))
# batch_list <- list(list(runid = 403,legend_text = "Flow (Total Permitted - New Met)"))
# batch_list <- list(list(runid = 603,legend_text = "Flow (2.6 mgd & 40% Flow-by - New Met)"))

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

  sdate <- min(dat_join$date)
  edate <- max(dat_join$date)

  #################################################################################################
  # FDC PLOT
  #################################################################################################

  y_axis_ticks = c(0.10,1,5,10,25,100,400)

  # FLOW DURATION CURVE PLOTS ------
  png(file=paste(export_path,"fdc_",runid_i,".png",sep=""),width=560, height=450)
  hydroTSM::fdc(
    cbind(dat_join$Qnatural, dat_join$Qout),
    yat = y_axis_ticks,
    main=paste("Flow Duration Curve\nRunid: ",runid_i," (",sdate," to ",edate,")",sep=""),
    leg.txt = c("Flow (Natural)",legend_text_i),
    ylab = "Q, [cfs]",
    ylim=c(0.01, 500)
  )

  # add second y-axis with mgd units
  axis(side = 4, at = y_axis_ticks*1.5472286365100711, labels = y_axis_ticks, col="black",col.axis="black")
  mtext("Q, [mgd]",side=4,col="black",line=1, adj = 0)
  

  # add location of 0.5 mgd flowby to plot
  # abline(h=0.5*1.5472286365100711, col="black", lty = "twodash")
  dev.off()

 
  ################################################################################################
  # HYDROGRAPH PLOT - DROUGHT PERIOD
  ################################################################################################
  
  legend_text_z <- c("Flow (Natural)",
                     legend_text_i
  )

  # DROUGHT PERIOD PLOT
  # REGULAR Y-AXIS ------------------------------------------------------------
  xmn <- as.Date('1999-01-01')
  xmx <- as.Date('1999-12-31')
  png(paste(export_path,"/hydrograph_dry_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)
  # png(paste(export_path,"/hydrograph_Qnatural_Qout_",xmn,"_",xmx,"_",runid_i,".png",sep=""), width = 1100, height = 600)

  ymn <- 0
  ymx <- 110
  par(mar = c(5,5,2,5))
  plot(as.numeric(dat_join$Qnatural)~as.Date(dat_join$date),type = "l", lty=2, lwd = 1,
       main=paste("Hydrograph\nRunid: ",runid_i," (",sdate," to ",edate,")",sep=""),
       ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="Flow (cfs)",xlab=paste("\nDate\n",xmn,"to",xmx))
  par(new = TRUE)
  plot(as.numeric(dat_join$Qout)~as.Date(dat_join$date),type = "l",col='brown3', lwd = 2,
       axes=FALSE,ylim=c(ymn,ymx),xlim=c(xmn,xmx),ylab="",xlab="")

  legend("topright",legend=c(legend_text_z),col=c("black","brown3"), lty=c(2,1), lwd=c(1,2), cex=1)
  dev.off()
  
  ################################################################################################
  ################################################################################################
 
} # close loop
################################################################################################



################################################################################################
################################################################################################
# NUMBER OF DAYS STORAGE IS BELOW 50%
maxcapacity <- 1941.47
capaity50pct <- maxcapacity*0.5

#402
rseg_bc_dat_402 <- om_get_rundata(352078, 402, site = omsite)
rseg_bc_dat_402_df <- data.frame(rseg_bc_dat_402)

imp_qa_402 <- sqldf(paste("select year,month,day, impoundment_Storage
                 from 'rseg_bc_dat_402_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
length(imp_qa_402$impoundment_Storage)

#602
rseg_bc_dat_602 <- om_get_rundata(352078, 602, site = omsite)
rseg_bc_dat_602_df <- data.frame(rseg_bc_dat_602)

imp_qa_602 <- sqldf(paste("select year,month,day, impoundment_Storage
                 from 'rseg_bc_dat_602_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
length(imp_qa_602$impoundment_Storage)

#2
# rseg_bc_dat_2 <- om_get_rundata(352078, 2, site = omsite)
# rseg_bc_dat_2_df <- data.frame(rseg_bc_dat_2)
# 
# imp_qa_2 <- sqldf(paste("select year,month,day, impoundment_Storage
#                  from 'rseg_bc_dat_2_df' WHERE impoundment_Storage <",capaity50pct,sep=""))
# length(imp_qa_2$impoundment_Storage)
################################################################################################
################################################################################################

