library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")


################################################################################################
################################################################################################
# get all upstream Rsegs

# rivseg = 'RU4_6040_6030'
# 
# # Get all segs above rivseg of interest
# # Read data that requires file download
# download_read <- function(url, filetype, zip) {
#   localpath <- tempdir()
#   filename <- basename(url)
#   filepath <- paste(localpath,"\\", filename, sep="")
# 
#   download.file(url, filepath)
# 
#   if(zip==TRUE){
#     folder <- unzip(filepath, exdir=localpath)
#     filepath <- grep(".*.csv.*", folder, value=TRUE)
#   }
#   if(filetype=="csv"){
#     df <- read.csv(file=filepath, header=TRUE, sep=",")
#   }
#   if(filetype=="shp"){
#     layer <- gsub("\\.zip", "", filename)
#     df <- read_sf(dsn=localpath, layer=layer)
#   }
#   if(filetype!="csv" & filetype!="shp"){
#     message(paste("Error in download_read(): filetype must be 'csv' or 'shp'"))
#   }
#   return(df)
# }
# 
# #----From VAhydro----
# segs <- list()
# segs$all <- download_read(url=paste(site,"/vahydro_riversegs_export",sep=""), filetype="csv", zip=FALSE)
# segs$all$riverseg <- str_replace(segs$all$hydrocode, 'vahydrosw_wshed_', '') #prerequisite for fn_extract_basin()
# upstream_segs <- fn_extract_basin(segs$all, rivseg)
# print(upstream_segs$riverseg)
# print(upstream_segs$hydroid)

################################################################################################
################################################################################################

################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 258123 # Rapidan River
fac_om_id <- 348716 # WILDERNESS SERVICE AREA:Rapidan River
runid <- 601 #6001
################################################################################################

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

sort(colnames(rsegdat_df))
sort(colnames(facdat_df))

#-------------------------------------------------------------------------

SML <- om_quantile_table(facdat, metrics = c("wd_mgd","unmet_demand_mgd", "Qintake", "Qriver","Qreach", "Qreach14","Qriver_up", "vwp_max_mgd", "vwp_base_mgd","vwp_pumptier_mgd"),
                         rdigits = 3,
                         quantiles = c(0,0.01,0.05,0.1,0.25,0.5,1.0))
kable(SML,'markdown')
test<-sqldf('select wd_mgd,Qreach,unmet_demand_mgd, vwp_max_mgd, vwp_base_mgd,vwp_pumptier_mgd,flowby, year, month, day from facdat_df
      where vwp_pumptier_mgd < 3 and unmet_demand_mgd > 0')


################################################################################################
################################################################################################


df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_401', 'runid_401', 'runid_601', 'runid_601', 'runid_601'),
  'metric' = c('l90_Qout', 'wd_cumulative_mgd','l90_Qout', 'wd_mgd', 'wd_cumulative_mgd'),
  'runlabel' = c('L90_400', 'wdc_mgd_400', 'l90_600', 'wd_mgd_600', 'wdc_mgd_600')
)
cc_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export", ds = ds
)


riv_data = fn_extract_basin(cc_data,'RU4_6040_6030')


# summaries since landseg data *COULD BE* summarized in the database.
rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_401', 'runid_601'),
  'metric' = c('Runit','Runit','Runit','Runit'),
  'runlabel' = c('Runit_400', 'Runit_600', 'Runit_401', 'Runit_601')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
riv_rodata = fn_extract_basin(ro_data,'RU4_6040_6030')
