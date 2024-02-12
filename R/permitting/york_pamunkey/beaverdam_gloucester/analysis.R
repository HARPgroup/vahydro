basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library("hydrotools")

library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")

elid = 348760  # Gloucster facility
relid = 352111  # Beaverdam subshed/reservoir
runid=401
gage_number = '01667500' # Rapidan
startdate <- "1984-10-01"
enddate <- "2020-09-30"
pstartdate <- "2008-04-01"
penddate <- "2008-11-30"


rmarkdown::render(
  '/usr/local/home/git/vahydro/R/OWS_summaries/model_run_brief.Rmd', 
  output_file = '/WorkSpace/modeling/projects/james_river/bedford_hydro/te_bedford_v01.docx', 
  params = list( 
    doc_title = 'Instream Flows Analysis – Bedford Hydropower', model_feature = 68319, 
    scenario = "runid_401", model_version= "vahydro-1.0", cu_pre_var="Qreach", 
    cu_post_var="Qbypass", table_cols=1, model_pid = 7276733,
    image_names =c(), image_descriptions =c()
  )
)

# 
runid = 401
hdata <- om_get_rundata(elid, runid, site=omsite)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qreach", "impoundment_use_remain_mg", "available_mgd", "base_demand_mgd", "wd_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[101:105,c("Qreach", "impoundment_use_remain_mg", "available_mgd", "base_demand_mgd")]
quantile(hdata$impoundment_use_remain_mg, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)

hydroTSM::fdc(hdata[,c("Qintake", "Qbypass")])


rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "impoundment_Qin", "local_channel_Qout", "local_channel_Qin",
    "Runit", "Qlocal"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])

# Ware Creek (channel object)
melid = 223551  
mdata <- om_get_rundata(melid, runid, site=omsite)
m_stats <- om_quantile_table(
  mdata, 
  metrics = c(
    "Qin", "Qout", "Runit"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(m_stats,'markdown')

deets <- as.data.frame(mdata[,c(
  "year", "month", "day", "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
)])

roelid = 223567 
runid = 401
rodata <- om_get_rundata(roelid, runid, site=omsite)
quantile(rodata$Runit)
