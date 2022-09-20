# Unable to install the HASP package on deq1 server using the recommended method: https://github.com/USGS-R/HASP
# Load USGS HASP package function files explicitly: 
source("https://raw.githubusercontent.com/USGS-R/HASP/main/R/gwl_single_sites.R")
source("https://raw.githubusercontent.com/USGS-R/HASP/main/R/frequency_analysis.R")
source("https://raw.githubusercontent.com/USGS-R/HASP/main/R/ggplot2_utils.R")


##########################################################################################
##########################################################################################
##########################################################################################
# rm(list = ls())  #clear variables
library(dplyr)
library(dataRetrieval)
library(ggplot2)
library(sqldf)

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = ''))

save_directory = '/var/www/html/images/dh'
# save_directory = 'C:/Users/nrf46657/Desktop/GitHub/vahydro/drupal/dh_drought/src/r/gw_plots'


#Pull in list of all drought USGS well dH Features 
URL <- paste(base_url,"drought-wells-export", sep = "/")
#well_list <- read.table(URL,header = TRUE, sep = ",")
well_list <- read.csv(URL, sep = ",")


# select eastern shore wells only
# well_list <- sqldf("SELECT *
#                     FROM well_list
#                     WHERE `Feature.Name` LIKE '%110S%'
#                     OR `Feature.Name` LIKE '%103A%'
#                    ")

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
  
  # print(save_directory)

  plt <- monthly_frequency_plot(dv,
                               gwl_data,
                               parameter_cd = parameterCd,
                               plot_title = title,
                               y_axis_label = y_axis_label,
                               flip = TRUE)

  # img_name <- paste(save_directory,'/usgs_',site,'_monthly_frequency_plot.png',sep = '')
  # png(img_name)
  # print(plt)
  # dev.off()
  ggsave(plot = plt, file=paste('usgs_',site,'_monthly_frequency_plot.png',sep = ''), path = save_directory , width=6, height=5)
} # end usgs well for loop
