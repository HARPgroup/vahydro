library(tictoc) #time elapsed
library(beepr) #play beep sound when done running

###################################################################################################### 
# LOAD FILES
######################################################################################################
site <- "http://deq2.bse.vt.edu/d.dh/"
  
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

#DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
localpath <- tempdir()
filename <- paste("vahydro_riversegs_export.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste(site,"vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
#MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)
# river_shp <- readOGR(paste(hydro_tools_location,'/GIS_LAYERS/MajorRivers',sep = ''), "MajorRivers")

#DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_centroid_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD MAPPING FUNCTIONS
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

######################################################################################################
### USER INPUTS  #####################################################################################
######################################################################################################

#----------- RUN SINGLE MAP --------------------------
minorbasin.mapgen(minorbasin = "BS",
                  metric = "l30_Qout",
                  runid_a = "runid_11",
                  runid_b = "runid_13")

#----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS
minorbasin <- c("NR", "YP", "EL", "TU", "RL", "OR", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
metric <- c("l90_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_13")

#NORTHERN BASINS ONLY (FOR CC SCENARIOS)
minorbasin <- c("YP", "EL", "RL", "PU", "RU", "YM", "JA", "PM", "YL", "PL", "JU", "JB", "JL","PS","ES")
metric <- c("l30_cc_Qout", "l90_cc_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_17","runid_19","runid_20")


tic("Total")

it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
for (mb in minorbasin) {
  print(paste("PROCESSING MINOR BASIN ",it," OF ",length(minorbasin),": ",mb,sep=""))
  
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))

    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      minorbasin.mapgen(mb,met,runid_a,rb) 

    } #CLOSE runid FOR LOOP 

  } #CLOSE metric FOR LOOP 
  
  it <- it + 1
} #CLOSE minorbasin FOR LOOP  
  
toc()
beep(3)
#------------------------------------------------------------------
