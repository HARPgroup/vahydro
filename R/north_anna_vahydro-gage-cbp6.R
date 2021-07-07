# North anna gage, vahydro, cbp6
# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# vahydro model at the gage
dam_elid = 207923 
lake_elid = 207925 
elid = 207885 @ YP3_6700_6670
runid = 11
model_gage <- fn_get_runfile(elid, runid, site = omsite,  cached = FALSE, use_tz = 'UTC');
mode(model_gage) <- 'numeric'
model_gage <- om_get_rundata(elid, runid, site = omsite, FALSE, FALSE)
model_gage <- zoo(model_gage, order.by=as.Date(index(model_gage), format="%m/%d/%Y", tz ='UTC'))
model_dam <- om_get_rundata(dam_elid, runid, site = omsite, FALSE, FALSE)
model_dam <- zoo(model_dam, order.by=as.Date(index(model_dam), format="%m/%d/%Y", tz ='UTC'))
model_lake <- om_get_rundata(lake_elid, runid, site = omsite, FALSE, FALSE)
model_lake <- zoo(model_lake, order.by=as.Date(index(model_lake), format="%m/%d/%Y", tz ='UTC'))
model_lake$storage_pct <- as.numeric(model_lake$use_remain_mg) * 3.07 / as.numeric(model_lake$maxcapacity)
# Get bechtel model and historic evels
hist_lake_raw = read.csv("http://deq1.bse.vt.edu:81/data/proj3/components/lake_anna/lake_anna_bechtel.csv")
hist_lake_raw$hist_out_cfs <- (hist_lake_raw$outvol_7day_acft/3.07) * 1.547/7.0
hist_lake <- zoo(hist_lake_raw, order.by = as.Date(hist_lake_raw$thisdate, format="%m/%d/%Y", tz ='UTC') )

sdate = as.Date(min(index(model_gage)))
edate = as.Date(max(index(model_gage)))

# gage data: USGS 01671020 NORTH ANNA RIVER AT HART CORNER NEAR DOSWELL, VA
gage <- gage_import_data_cfs('01671020', sdate, edate) # 

# raw cbp model at gage
cbp6_raw <- model_import_data_cfs('YP3_6330_6700', 'p6/p6_gb604', 'CFBASE30Y20180615', '1984-01-01', '2014-12-31', site = omsite)
cbp6_gage <- sqldf("select date,avg(flow) as flow from cbp6_raw group by date")
# Convert to zoo for easy timestamp handling
cbp6_gage <- zoo(cbp6_gage, order.by = as.Date(cbp6_gage$date, format="%Y-%m-%d", tz ='UTC') )
# note: om_get_rundata already returns zoo
gage <- zoo(gage, order.by = as.Date(as.character(gage$date), format="%Y-%m-%d", tz ='UTC') )

# raw cbp model at dam
cbp6_dam_raw <- model_import_data_cfs('YP2_6390_6330', 'p6/p6_gb604', 'CFBASE30Y20180615', '1984-01-01', '2014-12-31', site = omsite)
# Convert to zoo for easy timestamp handling
# alternative is to download directly since the model_import_data_cfs seems to timeout?
cbp6_dam_raw <- read.csv("http://deq1.bse.vt.edu:81/p6/p6_gb604/out/river/CFBASE30Y20180615/stream/YP2_6390_6330_0111.csv")
names(cbp6_dam_raw) <- c('year', 'month', 'day', 'hr', 'flow')
cbp6_dam_raw$date <- as.Date(paste0(cbp6_dam_raw$year,"-",cbp6_dam_raw$month,"-",cbp6_dam_raw$day))
cbp6_dam <- sqldf("select date,avg(flow) as flow from cbp6_dam_raw group by date")
# note: om_get_rundata already returns zoo
cbp6_dam <- zoo(cbp6_dam, order.by = as.Date(cbp6_dam$date, format="%Y-%m-%d", tz ='UTC') )

vwp_dam_raw <- read.csv("/Workspace/modeling/projects/york_river/north_anna/data/NAD_release_vwp_reported.csv")
vwp_dam_raw$thisdate <- as.Date(vwp_dam_raw$thisdate, format="%m/%d/%Y", tz ='UTC')
vwp_dam_raw$lake_elev <- as.numeric(vwp_dam_raw$lake_elev)
vwp_dam_raw$qrelease_cfs <- as.numeric(vwp_dam_raw$qrelease_cfs)
# note: om_get_rundata already returns zoo
vwp_dam <- zoo(vwp_dam_raw, order.by = vwp_dam_raw$thisdate )


par(mar = c(5,5,3,5))
plot(vwp_dam$lake_elev,
  ylab="Lake Surface Elevation (ft asl)",
  ylim = c(200,300), type="l", lwd=4,
  col='purple', xlab="Date", las=2,
  main = paste("North Anna Dam:",sdate,'to',edate)
)
lines(
  model_lake$lake_elev,
  col='black',
  ylim=c(200,300)
) 


hydro_zoom <- function(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, sdate, edate) {
  # Zoom in on 2002
  model_gagezoom <- window(
    model_gage, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  )  # Zoom in on 2002
  hist_lake_zoom <- window(
    hist_lake, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  )
  
  model_damzoom <- window(
    model_dam, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  model_lakezoom <- window(
    model_lake, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  mode(model_lakezoom) <- "numeric"
  cbp6_zoom <- window(
    cbp6_gage, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  cbp6_dam_zoom <- window(
    cbp6_dam, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  gagezoom <- window(
    gage, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  vwp_zoom <- window(
    vwp_dam, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  mode(vwp_zoom) <- "numeric"
  ymx = max(
    c(
      max(as.numeric(gagezoom$flow),na.rm=TRUE), 
      max(as.numeric(cbp6_zoom$flow),na.rm=TRUE), 
      max(as.numeric(model_gagezoom$Qout),na.rm=TRUE)
    )
  )
  
  # Plot at North Anna Dam
  # NOTE: first y value must be type numeric to make labels work in zoo plots.
  #       but if you convert to numeric in the plot statement, it will screw
  #       up the x-axis labeling
  par(mar = c(5,5,2,5))
  plot(vwp_zoom$lake_elev,
       ylab="Lake Surface Elevation (ft asl)",
       ylim = c(200,300), type="l", lwd=4,
       col='purple', xlab="Date", las=2,
       main = paste("North Anna Dam:",sdate,'to',edate)
  )
  lines(
    model_lakezoom$lake_elev,
    col='black',
    ylim=c(200,300)
  ) 
  par(new = TRUE)
  plot(vwp_zoom$qrelease_cfs,ylim=c(0,100),lwd=4,col='yellow',axes=FALSE,xlab='',ylab='') 
  lines(cbp6_dam_zoom$flow,col='orange') 
  lines(
    model_damzoom$Qout,
    col='green'
  ) 
  lines(
    model_lakezoom$Qin,
    col='purple'
  ) 
  legend("topleft",
         c("Hist Elev", "VAH Elev","Hist Release", "VAH Release", "CBP6 Release", "Lake Inflow"),
         fill=c("blue", "black", "yellow", "orange","green","purple")
  )
  axis(side = 4)
  mtext(side = 4, line = 3, 'Flow(cfs)')
  
  
  # Plot at USGS Gage 01671020
  
  par(mar = c(5,5,2,5))
  plot(
    gagezoom$flow, col='blue',
    ylab="Flow (cfs)",
    ylim = c(0, ymx), type="l",
    main = paste("USGS 01671020",sdate,'to',edate)
  )
  lines(model_gagezoom$Qout,col='red')
  lines(cbp6_zoom$flow,col='orange') 
  lines(model_damzoom$Qout,col='brown') 
  legend("topleft",
         c("USGS", "VAH Gage", "CBP6 Gage", "VAH Dam"),
         fill=c("blue", "red","orange", "brown")
  )
  
  plot(
    model_lakezoom$whtf_natevap_mgd, 
    ylim=c(0,110),
    xlab="Date",
    main=paste("CBP Model ET vs. Extra Evap from WHTF", sdate,"TO",edate),
    ylab="Evaporation (mgd)"
  )
  lines(model_lakezoom$whtf_evap12_mgd, col="orange")
  legend("topleft",
         c("PET * Lake Surface Area", "VAHydro Power Reg"),
         fill=c("black", "orange")
  )
  
  mean(as.numeric(gagezoom$flow),na.rm=TRUE)
  # 37.63748
  mean(as.numeric(cbp6_zoom$flow),na.rm=TRUE)
  # 66.02988
  mean(as.numeric(model_gagezoom$Qout),na.rm=TRUE)
  # 41.05855
}

# this is 2002 drought, fit not very good
# suggests that LLCP was not invoked
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, '2002-06-01', '2002-10-31')
# suggests that LLCP was not invoked
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, '2002-09-01', '2002-12-31')
# this is excellent fit due to lake level contingency
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, '1984-10-01', '2005-09-30')
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, '1991-10-01', '1992-09-30')
# VAHydro misses refill here, likely because
# it is over-estimating evap loss and therefore drawdown
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, hist_lake, cbp6_dam, vwp_dam, '2007-06-01', '2008-03-31')

nad2002 <- window(
  model_lake, 
  start = as.Date('2001-01-01' ), 
  end = as.Date( '2002-10-31' )
)
quantile(nad2002$lake_elev)

quantile(bechtel_hist$hist_lake_elev)
group2(model_gage$Qout)
group2(gage)
group2(cbp6_gage)

# VAHydro Regression WHTF evap
quantile(model_lake$whtf_reg_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# Bechtel model evap from 1 & 2 
quantile(model_lake$whtf_evap12_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# Bechtel model evap from 1 & 2 
quantile(model_lake$whtf12_extra_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# Natural lake surface evap from CBP
quantile(model_lake$whtf_natevap_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# Natural lake surface evap from CBP
quantile(model_lake$et_in, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# WD from DOMLA
quantile(model_lake$child_wd_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# PS from DOMLA
quantile(model_lake$child_ps_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
# PS from DOMLA
quantile( (model_lake$child_wd_mgd - model_lake$child_ps_mgd), probs=c(0,0.1,0.25,0.5,0.75,0.9, 1.0))
mean(model_lake$child_wd_mgd - model_lake$child_ps_mgd)
mean(model_lake$child_wd_mgd)
mean(model_lake$child_ps_mgd)


plot(model_lakezoom$whtf_natevap_mgd, model_lakezoom$whtf_evap12_mgd, ylim=c(0,110))
breg <- lm(as.numeric(model_lakezoom$whtf_evap12_mgd) ~ as.numeric(model_lakezoom$et_in))
summary(breg)

# Withdrawal and Discharge
lm(model_lake$child_ps_mgd ~ model_lake$child_wd_mgd)

model_lake_et_calib <- window(
  model_lake,
  start = as.Date('1984-10-01' ), 
  end = as.Date('2005-09-30' )
)
model_lake_wy2k <- window(
  model_lake,
  start = as.Date('2001-10-01' ), 
  end = as.Date('2002-09-30' )
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
quadratic_model <- lm(
  model_lake_et_calib$whtf_evap12_mgd ~ model_lake_et_calib$whtf_natevap_mgd + I(model_lake_et_calib$whtf_natevap_mgd^2)
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model)
plot(
  model_lake_et_calib$whtf_natevap_mgd, 
  model_lake_et_calib$whtf_evap12_mgd, 
  ylim=c(0,110),
  ylab="Lake Surface Evap Including Warm Water (mgd)",
  xlab="Lake Surface Area * PET (mgd)",
  main="CBP Model ET vs. Extra Evap from WHTF"
)
plot(model_lake_wy2k$whtf_natevap_mgd, ylim=c(0,110),xlab="CBP Model ET vs. Extra Evap from WHTF")
lines(model_lake_wy2k$whtf_evap12_mgd, col="orange")

plot(model_lake_wy2k$whtf_natevap_mgd, model_lake_wy2k$whtf_evap12_mgd, ylim=c(0,110))

