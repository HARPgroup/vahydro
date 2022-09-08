# remotes::install_gitlab("water/stats/hasp",
#                         host = "code.usgs.gov",
#                         build_opts = c("--no-resave-data",
#                                        "--no-manual"),
#                         build_vignettes = TRUE, 
#                         dependencies = TRUE)

rm(list = ls())  #clear variables
library(HASP)
library(dataRetrieval)
library(ggplot2)
library(sqldf)

save_directory = '/var/www/html/images/dh'
# save_directory = 'C:/Users/nrf46657/Desktop/GitHub/vahydro/drupal/dh_drought/src/r/gw_plots'

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = ''))

# load libraries
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/")); 
source(paste(basepath,"auth.private",sep = '/'))
token <- rest_token (base_url, token, rest_uname = rest_uname, rest_pw = rest_pw) #token needed for REST
site <- base_url


#Pull in list of all drought USGS well dH Features 
URL <- paste(site,"drought-wells-export", sep = "/")
#well_list <- read.table(URL,header = TRUE, sep = ",")
well_list <- read.csv(URL, sep = ",")


# select eastern shore wells only
well_list <- sqldf("SELECT *
                    FROM well_list
                    WHERE `Feature.Name` LIKE '%110S%'
                    OR `Feature.Name` LIKE '%103A%'
                   ")

hydrocodes <- well_list$hydrocode

# j = 1
#Begin loop to run through each USGS gage 
for (j in 1:length(hydrocodes)) {
  siteNumber <- hydrocodes[j]
  siteNumber <- toString(siteNumber)
  #print(paste("USGS siteNumber: ", siteNumber, sep='')); 
  cat("EXECUTING WELL ",j," OF ",length(hydrocodes)," - USGS siteNumber: ", siteNumber,"\n",sep="")
  site = unlist(strsplit(siteNumber, split='_', fixed=TRUE))[2]

  #Field GWL data:
  gwl_data <- dataRetrieval::readNWISgwl(site)
  
  # Daily data:
  parameterCd <- "72019" #Depth to water level, feet below land surface
  statCd <- "00001" # MAXIMUM
  # statCd <- "00002" # MINIMUM
  # statCd <- "00003"# MEAN
  # statCd <- "00008" # MEDIAN
  dv <- dataRetrieval::readNWISdv(site,
                                  parameterCd,
                                  statCd = statCd)
  
  y_axis_label <- readNWISpCode(parameterCd)$parameter_nm
  title <- paste(site, " - ", readNWISsite(site)$station_nm, sep="")
  
  plt <- HASP::monthly_frequency_plot(dv,
                               gwl_data,
                               parameter_cd = parameterCd,
                               plot_title = title,
                               y_axis_label = y_axis_label,
                               flip = TRUE)

  ggsave(file=paste('usgs_',site,'_monthly_frequency_plot.png',sep = ''), path = save_directory , width=6, height=5)
} # end usgs well for loop
