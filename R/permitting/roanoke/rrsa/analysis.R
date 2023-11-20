basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')

elid = 249923 # Lake Gaston impoundment
relid = 211633 # James River
celid = 211669 # channel element in james model
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
runid = 2
hdata <- om_get_rundata(249923, runid, site=omsite, hydrowarmup = FALSE)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qin", "min_flows", "Qout", "wd_mgd", "release", "lake_elev", "use_remain_mg", "days_remaining", "Storage"
  ),
  quantiles=c(0,0.02,0.05,0.25, 0.5, 0.75, 1.0),
  rdigits = 1
)
kable(wr_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qin", "min_flows", "Qout", "Storage", "use_remain_mg"
)])
deets[6600:6800,]

drought <- sqldf("select * from deets where Storage < 1")

# Kerr imp
kdata <- om_get_rundata(249383, runid, site=omsite, hydrowarmup = FALSE)
kr_stats <- om_quantile_table(
  kdata, 
  metrics = c(
    "Qin", "min_flows", "Qout", "wd_mgd", "release", "lake_elev", "use_remain_mg", "days_remaining", "Storage"
  ),
  quantiles=c(0,0.05,0.2, 0.5, 0.75, 1.0),
  rdigits = 1
)
kable(kr_stats,'markdown')
