# North anna gage, vahydro, cbp6
# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# vahydro model at the gage
dam_elid = 207923 
lake_elid = 207925 
elid = 207885
runid = 11
model_gage <- fn_get_runfile(elid, runid, site = omsite,  cached = FALSE, use_tz = 'UTC');
mode(model_gage) <- 'numeric'
model_gage <- om_get_rundata(elid, runid, site = omsite, FALSE, FALSE)
model_dam <- om_get_rundata(dam_elid, runid, site = omsite, FALSE, FALSE)
model_lake <- om_get_rundata(lake_elid, runid, site = omsite, FALSE, FALSE)
model_lake$storage_pct <- as.numeric(model_lake$use_remain_mg) * 3.07 / as.numeric(model_lake$maxcapacity)


sdate = as.Date(min(index(model_gage)))
edate = as.Date(max(index(model_gage)))

# gage data
gage <- gage_import_data_cfs('01671020', sdate, edate)

# raw cbp model at gage
cbp6_raw <- model_import_data_cfs('YP3_6330_6700', 'p6/p6_gb604', 'CFBASE30Y20180615', '1984-01-01', '2014-12-31', site = omsite)
# Convert to zoo for easy timestamp handling
# note: om_get_rundata already returns zoo
gage <- zoo(gage, order.by = as.Date(as.character(gage$date), format="%Y-%m-%d", tz ='UTC') )
cbp6_gage <- zoo(cbp6_raw, order.by = as.Date(cbp6_raw$date, format="%Y-%m-%d h:i:s", tz ='UTC') )

hydro_zoom <- function(gage, model_gage, model_dam, model_lake, cbp6_gage, sdate, edate) {
  # Zoom in on 2002
  model_gagezoom <- window(
    model_gage, 
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
  cbp6_zoom <- window(
    cbp6_gage, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  gagezoom <- window(
    gage, 
    start = as.Date(sdate ), 
    end = as.Date(edate )
  );
  ymx = max(
    c(
      max(as.numeric(gagezoom$flow),na.rm=TRUE), 
      max(as.numeric(cbp6_zoom$flow),na.rm=TRUE), 
      max(as.numeric(model_gagezoom$Qout),na.rm=TRUE)
    )
  )
  par(mar = c(5,5,2,5))
  plot(
    as.numeric(gagezoom$flow), col='blue',
    ylab="Flow at USGS 01671020 (cfs)",
    ylim = c(0, ymx), type="l",
    main = paste("North Anna River:",sdate,'to',edate)
  )
  lines(as.numeric(model_damzoom$Qout),col='brown') 
  lines(as.numeric(model_gagezoom$Qout),col='red')
  lines(as.numeric(cbp6_zoom$flow),col='orange') 
  legend("topleft",
         c("USGS", "VAH Gage", "CBP6 Gage", "VAH Dam", "VAH Elev"),
         fill=c("blue","brown", "red", "orange", "black")
  )
  par(new = TRUE)
  lines(
    as.numeric(100.0*model_lakezoom$storage_pct),
    col='black',
    ylim=c(0,120)
  ) 
  axis(side = 4)
  mtext(side = 4, line = 3, 'Lake Storage (%)')
  
  mean(as.numeric(gagezoom$flow),na.rm=TRUE)
  # 37.63748
  mean(as.numeric(cbp6_zoom$flow),na.rm=TRUE)
  # 66.02988
  mean(as.numeric(model_gagezoom$Qout),na.rm=TRUE)
  # 41.05855
}

# this is 2002 drought, fit not very good
# suggests that LLCP was not invoked
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, '2002-06-01', '2002-10-31')
# this is excellent fit due to lake level contingency
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, '2007-06-01', '2007-10-31')
# VAHydro misses refill here, likely because
# it is over-estimating evap loss and therefore drawdown
hydro_zoom(gage, model_gage, model_dam, model_lake, cbp6_gage, '2007-06-01', '2008-03-31')


group2(model_gage$Qout)
group2(gage)
group2(cbp6_gage)
