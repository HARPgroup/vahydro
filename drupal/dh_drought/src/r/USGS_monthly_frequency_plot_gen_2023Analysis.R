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

# save_directory = '/var/www/html/images/dh'
save_directory = 'C:/Users/nrf46657/Desktop/GitHub/plots'
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

hydrocodes <- "usgs_385607077381101" # Northern Virginia - Prince William County USGS Observation Well (49V 1)
hydrocodes <- "usgs_391542077423801" # Northern Virginia - Harper's Ferry DEQ Observation Well (49Y 1 SOW 022)
hydrocodes <- "usgs_385638077220101" # Northern Virginia - Fairfax County USGS Observation Well (52V 2D)
hydrocodes <- "usgs_383423077245901" # Northern Virginia - Prince William County USGS Observation Well (51S 7)

hydrocodes <- "usgs_382150078424001" # Shenandoah - McGaheysville USGS Observation Well (41Q 1)
hydrocodes <- "usgs_390348078035501" # Shenandoah - Blandy Farm USGS Observation Well (46W 175)

hydrocodes <- "usgs_381002078094201" # Northern Piedmont - Gordonsville DEQ Observation Well (45P 1 SOW 030)

# 
# usgs_385607077381101_dv <- dv
# usgs_391542077423801_dv <- dv
# usgs_385638077220101_dv <- dv
# usgs_383423077245901_dv <- dv

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
  
  
  ######################################################
  dv_raw <- dv
  dv <- dv_raw
  dv$Date <- as.character(as.Date(as.character(dv$Date), format = "%Y-%m-%d"))
  qa <-  sqldf(paste('SELECT *
                      FROM dv A
                      WHERE Date > "2002-01-01" AND Date < "2003-01-01"
                      ORDER BY Date
                      ',
                     sep=""))
  
  dv <- qa
  # WHERE CAST(A.Date AS Date) >= "2002-01-01"
  # sapply(dv,class)
  ######################################################
  
  
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
