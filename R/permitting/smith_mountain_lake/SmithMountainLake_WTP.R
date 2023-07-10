library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")


################################################################################################
################################################################################################
# get all upstream Rsegs

rivseg = 'OR4_8271_8120'

# Get all segs above rivseg of interest
# Read data that requires file download
download_read <- function(url, filetype, zip) {
  localpath <- tempdir()
  filename <- basename(url)
  filepath <- paste(localpath,"\\", filename, sep="")
  
  download.file(url, filepath)
  
  if(zip==TRUE){
    folder <- unzip(filepath, exdir=localpath)
    filepath <- grep(".*.csv.*", folder, value=TRUE)
  }
  if(filetype=="csv"){
    df <- read.csv(file=filepath, header=TRUE, sep=",")
  }
  if(filetype=="shp"){
    layer <- gsub("\\.zip", "", filename)
    df <- read_sf(dsn=localpath, layer=layer)
  } 
  if(filetype!="csv" & filetype!="shp"){
    message(paste("Error in download_read(): filetype must be 'csv' or 'shp'"))
  }
  return(df)
}

#----From VAhydro----
segs <- list()
segs$all <- download_read(url=paste(site,"/vahydro_riversegs_export",sep=""), filetype="csv", zip=FALSE)
segs$all$riverseg <- str_replace(segs$all$hydrocode, 'vahydrosw_wshed_', '') #prerequisite for fn_extract_basin()
upstream_segs <- fn_extract_basin(segs$all, rivseg)
print(upstream_segs$riverseg)
print(upstream_segs$hydroid)

################################################################################################
################################################################################################

# SML Impoundment:
SML_om_id <- 252119 
runid <- 401
SMLdat <- om_get_rundata(SML_om_id, runid, site = omsite)
SMLdat_df <- data.frame(SMLdat)
sort(colnames(SMLdat_df))

SML_imp <- om_quantile_table(SMLdat_df, metrics = c(
  "sml_elev","lees_min","Tbrook", "Qbrook", "Rbrook", "impoundment_demand","impoundment_demand_met_mgd","impoundment_Storage","impoundment_use_remain_mg","impoundment_days_remaining","impoundment_Qin","impoundment_Qout",
  "Leesville_Lake_demand","Leesville_Lake_demand_met_mgd","Leesville_Lake_Storage","Leesville_Lake_use_remain_mg","Leesville_Lake_days_remaining","Leesville_Lake_Qout",
  "wd_mgd","pump_lees","refill_lees","Qin","Qout","release_sml","sml_use_remain_mg",
  "trigger1","trigger2","trigger3"
  ),
  rdigits = 2
)
kable(SML_imp,'markdown')

quantile(SMLdat$impoundment_Qout)
quantile(SMLdat$impoundment_Qin - SMLdat$impoundment_evap_mgd * 1.547 - SMLdat$impoundment_demand * 1.547)
mean(SMLdat$impoundment_Qin)
mean(SMLdat$impoundment_evap_mgd * 1.547)
mean(SMLdat$impoundment_Qout)
mean(SMLdat$Leesville_Lake_Qin)
mean(SMLdat$Leesville_Lake_evap_mgd * 1.547)
mean(SMLdat$Leesville_Lake_Qout)

mean(SMLdat$Rbrook)

mean(SMLdat$impoundment_Qin - SMLdat$impoundment_evap_mgd * 1.547 - SMLdat$impoundment_demand * 1.547)

mean(SMLdat$impoundment_Qin - SMLdat$impoundment_evap_mgd * 1.547 - SMLdat$impoundment_demand * 1.547)

################################################################################################
################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 252117 # Smith Mountain and Leesville Dams
fac_om_id <- 351208  # SML SERVICE AREA:Smith Mountain and Leesville Dams
runid <- 401
################################################################################################

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)


sort(colnames(rsegdat_df))
sort(colnames(facdat_df))

facdat_df$impoundment_use_remain_mg
facdat_df$lake_elev
#-------------------------------------------------------------------------

SML <- om_quantile_table(facdat_df, metrics = c("historic_monthly_pct","vwp_max_mgy","vwp_max_mgd",
                                                "vwp_base_mgd","wd_mgd","unmet_demand_mgd",
                                                "impoundment_use_remain_mg","lake_elev"),
                         rdigits = 3)
kable(SML,'markdown')


################################################################################################
################################################################################################
