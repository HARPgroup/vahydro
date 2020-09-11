library(tictoc) #time elapsed
library(beepr) #play beep sound when done running

###################################################################################################### 
# LOAD FILES
######################################################################################################
#site <- "https://deq1.bse.vt.edu/d.dh/"
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
MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)
#MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/rivnames/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)


#DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_centroid_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD RAW mp.all FILE
# mp.all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#LOAD MAPPING FUNCTIONS
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.SINGLE.SCENARIO.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.SINGLE.SCENARIO.R",sep = '/'))

######################################################################################################
### SCENARIO COMPARISONS #############################################################################
######################################################################################################
#----------- RUN SINGLE MAP --------------------------
# statewide.mapgen(metric = "l30_Qout",
#                  runid_a = "runid_11",
#                  runid_b = "runid_18")
# 
# statewide.mapgen(metric = "l30_cc_Qout",
#                  runid_a = "runid_11",
#                  runid_b = "runid_17")


# #----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS (9 figs)
metric <- c("l30_Qout","l90_Qout","7q10")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_12","runid_13","runid_18")

# 
#NORTHERN BASINS ONLY (FOR CC SCENARIOS) (6 figs)
metric <- c("l30_cc_Qout", "l90_cc_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_17","runid_19","runid_20")

# 
tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
print(paste("PROCESSING VA",sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      statewide.mapgen(met,runid_a,rb)
    } #CLOSE runid FOR LOOP
  } #CLOSE metric FOR LOOP
  it <- it + 1
toc()
beep(3)
# #------------------------------------------------------------------
# 
# ######################################################################################################
# ### SINGLE SCENARIO ##################################################################################
# ######################################################################################################
 # source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.SINGLE.SCENARIO.R",sep = '/'))
#----------- RUN SINGLE MAP --------------------------
# statewide.mapgen.SINGLE.SCENARIO(metric = "consumptive_use_frac",
#                                  runid_a = "runid_13")

 # statewide.mapgen.SINGLE.SCENARIO(metric = "consumptive_use_frac",
 #                                  runid_a = "runid_18")

# #----------- RUN MAPS IN BULK --------------------------
# #ALL 21 MINOR BASINS - SINGLE SCENARIO (4 figs)
metric <- "consumptive_use_frac"
runid_a <- c("runid_11","runid_12","runid_13","runid_18")
# 
# #NORTHERN BASINS ONLY (FOR CC SCENARIO) (3 figs)
metric <- "consumptive_use_frac"
runid_a <- c("runid_17","runid_19","runid_20")

# 
tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
print(paste("PROCESSING VA",sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_a) {
      print(paste("......PROCESSING runid_a: ",rb,sep=""))
      statewide.mapgen.SINGLE.SCENARIO(met,rb)
    } #CLOSE runid FOR LOOP
  } #CLOSE metric FOR LOOP
  it <- it + 1
toc()
beep(3)
# #------------------------------------------------------------------
