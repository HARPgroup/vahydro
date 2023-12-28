#----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
#----------------------------------------------
#site <- base_url    #Specify the site of interest, either d.bet OR d.dh, taken from the config.R
# this is now set in config.local.R
#----------------------------------------------
source(paste(om_location,'R/summarize','rseg_elfgen.R',sep='/'))
library(stringr)
# dirs/URLs
# save_directory <- "/var/www/html/data/proj3/out"
library(hydrotools)
# authenticate
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

# Read Args
# argst <- commandArgs(trailingOnly=T)
# pid <- as.integer(argst[1])
# elid <- as.integer(argst[2])
# runid <- as.integer(argst[3])

#-------------------------
# save_directory <- 'C:/Users/nrf46657/Desktop/GitHub/om/R/summarize'
# save_directory <- "C:/Users/nrf46657/Desktop/VWP Modeling/City of Salem WTP/2023"
save_directory <- "C:/Users/nrf46657/Desktop/GitHub/vahydro/R/permitting/Salem WTP"
#-------------------------


pid <- 4713208
elid <- 249169

# runid.list <- c(217,616)
runid.list <- c(400,600)
legend_text <- c("8.00 mgd & No Flow-by",
                 "6.64 mgd & 85% Flow-by")

dat_all <- list()
#i<-1
for (i in 1:length(runid.list)) {
  
  runid <- runid.list[i]

  # Note: when we migrate to om_get_rundata()
  # we must insure that we do NOT use the auto-trim to water year
  # as we want to have the model_run_start and _end for scenario storage
  dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
  mode(dat) <- 'numeric'
  
  syear = as.integer(min(dat$year))
  eyear = as.integer(max(dat$year))
  # syear = 1984
  # eyear = 2005
  model_run_start <- min(dat$thisdate)
  model_run_end <- max(dat$thisdate)
  if (syear < (eyear - 2)) {
    sdate <- as.Date(paste0(syear,"-10-01"))
    edate <- as.Date(paste0(eyear,"-09-30"))
    flow_year_type <- 'water'
  } else {
    sdate <- as.Date(paste0(syear,"-02-01"))
    edate <- as.Date(paste0(eyear,"-12-31"))
    flow_year_type <- 'calendar'
  }
  dat <- window(dat, start = sdate, end = edate);
  mode(dat) <- 'numeric'
  scen.propname<-paste0('runid_', runid)
  
  cols <- names(dat)
  
  dat$Qbaseline <- dat$Qout +
    (dat$wd_cumulative_mgd - dat$ps_cumulative_mgd ) * 1.547
  
  Qbaseline <- mean(as.numeric(dat$Qbaseline) )
  if (is.na(Qbaseline)) {
    Qbaseline = Qout +
      (wd_cumulative_mgd - ps_cumulative_mgd ) * 1.547
  }
  
  datdf <- as.data.frame(dat)
  # modat <- sqldf("select month, avg(wd_cumulative_mgd) as wd_mgd, avg(ps_cumulative_mgd) as ps_mgd from datdf group by month")
  

  dat_all[[paste("datdf_",runid,sep='')]] <- datdf
  
} #end for loop  
  

###############################################
# RSEG FDC
###############################################
base_var <- "Qbaseline" #BASE VARIABLE USED IN FDCs AND HYDROGRAPHS
comp_var <- "Qout" #VARIABLE TO COMPARE AGAINST BASE VARIABLE, DEFAULT Qout

# build data frame of data needed for constructing the fdc curves
dat_base <- dat_all[[1]]
fdc_dat <- data.frame(dat_base[names(dat_base)== base_var])
#j <- 2
for (j in 1:length(dat_all)) {
  datpd_j <- dat_all[[j]]
  fdc_dat <- cbind(fdc_dat,datpd_j[names(datpd_j)== comp_var])
  colnames(fdc_dat)[which(names(fdc_dat) == comp_var)] <- paste(runid.list[j],comp_var,sep="_")
} # end for loop 


fname <- paste(
  save_directory,
  paste0(
    'fdc.',
    elid, '.',paste(runid.list, collapse = "."), '.png'
  ),
  sep = '/'
)
# FOR TESTING 
save_url <- save_directory
furl <- paste(
  save_url,
  paste0(
    'fdc.',
    elid, '.',paste(runid.list, collapse = "."), '.png'
  ),
  sep = '/'
)


if (legend_text != FALSE){
  legend_text = c("Baseline Flow",legend_text)
} else {
  legend_text = c("Baseline Flow",runid.list)
}


# head(fdc_dat[1])
# head(fdc_dat[2])
# max(fdc_dat[1])
# max(fdc_dat[2])

png(fname, width = 700, height = 700)

fdc_plot <- hydroTSM::fdc(cbind(fdc_dat),
                          # yat = c(300,500,1000,5000,10000),
                          yat = c(1, 5, 10, 50, 100, seq(0,round(max(fdc_dat),0), by = 500)),
                          leg.txt = legend_text,
                          main=paste("Flow Duration Curve","\n","(Model Flow Period ",sdate," to ",edate,")",sep=""),
                          ylab = "Flow (cfs)",
                          # ylim=c(1.0, 5000),
                          ylim=c(min(fdc_dat), max(fdc_dat)),
                          cex.main=1.75,
                          cex.axis=1.50,
                          leg.cex=2,
                          cex.sub = 1.2,
                          #pch = 20
                          pch = NA
                          )
dev.off()

print(paste("Saved file: ", fname, "with URL", furl))
###############################################
###############################################

