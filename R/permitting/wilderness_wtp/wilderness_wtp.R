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
runid <- 401 #6001
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

SML <- om_quantile_table(facdat_df, metrics = c("wd_mgd","unmet_demand_mgd", "Qintake", "Qriver","Qreach", "Qreach14","Qriver_up", "vwp_max_mgd", "vwp_base_mgd","vwp_pumptier_mgd"),
                         rdigits = 3,
                         quantiles = c(0,0.01,0.05,0.1,0.25,0.5,1.0))
kable(SML,'markdown')
test<-sqldf('select wd_mgd,Qreach,unmet_demand_mgd, vwp_max_mgd, vwp_base_mgd,vwp_pumptier_mgd,flowby, year, month, day from facdat_df
      where vwp_pumptier_mgd < 3 and unmet_demand_mgd > 0')


################################################################################################
################################################################################################