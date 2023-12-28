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

yelid = 277312 # Byllesby Hydro
uelid = 277310 # Buck hydro
relid = 277258 # New River
runid=401

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
ydata <- om_get_rundata(yelid, runid, site=omsite)
wr_stats <- om_quantile_table(
  ydata, 
  metrics = c(
    "Qreach", "Qturbine", "Qavail_divert", "Qbypass", "flowby", "Qintake"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 0.8, 0.9, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[1:5,c("Qreach", "Qintake", "reach_area_sqmi", "intake_drainage_area")]
quantile(hdata$wp_bypass, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)

udata <- om_get_rundata(uelid, runid, site=omsite)
wr_stats <- om_quantile_table(
  udata, 
  metrics = c(
    "Qreach", "Qturbine", "Qavail_divert", "Qbypass", "flowby", "Qintake"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 0.8, 0.9, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[1:5,c("Qreach", "Qintake", "reach_area_sqmi", "intake_drainage_area")]
quantile(hdata$wp_bypass, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)


hydroTSM::fdc(hdata[,c("Qintake", "Qbypass")])

