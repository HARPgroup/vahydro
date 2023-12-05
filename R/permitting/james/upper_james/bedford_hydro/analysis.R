basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library("hydrotools")

elid = 353101 #bedford hydro snowden
relid = 211633 # James River
celid = 211669 # channel element in james model
runid=400
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
runid = 600
hdata <- om_get_rundata(elid, runid, site=omsite)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qreach", "Qturbine", "Qavail_divert", "Qbypass", "flowby", "Qintake"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[1:5,c("Qreach", "Qintake", "reach_area_sqmi", "intake_drainage_area")]
quantile(hdata$wp_bypass, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)


rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "Qup", "ps_cumulative_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])

# Lake Moomaw
melid = 213673 
mdata <- om_get_rundata(melid, runid, site=omsite)
m_stats <- om_quantile_table(
  mdata, 
  metrics = c(
    "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(m_stats,'markdown')

deets <- as.data.frame(mdata[,c(
  "year", "month", "day", "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
)])


cdata <- om_get_rundata(celid, runid, site=omsite)
c_stats <- om_quantile_table(
  cdata, 
  metrics = c(
    "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(c_stats,'markdown')
lfcdata <- cdata[which(cdata$Qout < 1000),]
plot(100.0*(lfcdata$Storage / lfcdata$depth)/max(cdata$Storage / cdata$depth) ~ lfcdata$Qout, ylim=c(0,100))
plot(100.0*(cdata$Storage / cdata$depth)/max(cdata$Storage / cdata$depth) ~ cdata$Qout, ylim=c(0,100))
plot(100.0*(cdata$Storage / cdata$depth)/max(cdata$Storage / cdata$depth) ~ cdata$Qout, ylim=c(0,100), xlim=c(0,1000))
plot(100.0*(cdata$Storage / cdata$depth)/max(cdata$Storage / cdata$depth) ~ cdata$Qout, ylim=c(0,100), xlim=c(0,2000))

