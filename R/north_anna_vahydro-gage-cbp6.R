# North anna gage, vahydro, cbp6
# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# gage data
gage <- gage_import_data_cfs('01671020', sdate, edate)
# vahydro model at the gage
elid = 207885
runid = 11
model_gage <- fn_get_runfile(elid, runid, site = omsite,  cached = FALSE, use_tz = 'UTC');
mode(model_gage) <- 'numeric'

# raw cbp model at gage
cbp6_raw <- model_import_data_cfs('YP3_6330_6700', 'p6/p6_gb604', 'CFBASE30Y20180615', '1984-01-01', '2014-12-31')
# Convert to zoo for easy timestamp handling
gage <- zoo(gage, order.by = as.Date(gage$date, format="%Y-%m-%d", tz ='UTC') )
model_gage <- zoo(model_gage, order.by = as.Date(index(model_gage), format="%Y-%m-%d h:i:s", tz ='UTC') )
cbp6_gage <- zoo(cbp6_raw, order.by = as.Date(cbp6_raw$date, format="%Y-%m-%d h:i:s", tz ='UTC') )

# Zoom in on 2002
model_gage2k <- window(
  model_gage, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
cbp6_2k <- window(
  cbp6_gage, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
gage2k <- window(
  gage, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);

mean(as.numeric(gage2k$flow),na.rm=TRUE)
# 37.63748
mean(as.numeric(cbp6_2k$flow),na.rm=TRUE)
# 66.02988
mean(as.numeric(model_gage2k$Qout),na.rm=TRUE)
# 41.05855

ymx = max(
  c(
    max(as.numeric(gage2k$flow),na.rm=TRUE), 
    max(as.numeric(cbp6_2k$flow),na.rm=TRUE), 
    max(as.numeric(model_gage2k$Qout),na.rm=TRUE)
  )
)
par(mar = c(5,5,2,5))
plot(
  gage2k$flow, col='blue',
  ylab="Flow at USGS 01671020 (cfs)",
  ylim = c(0, ymx),
  main = "North Anna River: Raw CBP6 and CBP6 w/VAHydro Routing in 2002"
)
lines(model_gage2k$Qout,col='purple')
lines(cbp6_2k$flow,col='orange') 
legend("topleft",
       c("USGS", "VAHydro", "CBP6"),
       fill=c("blue","purple", "orange")
)