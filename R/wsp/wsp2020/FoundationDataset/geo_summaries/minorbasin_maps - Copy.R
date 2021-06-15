library(tictoc) #time elapsed
library(beepr) #play beep sound when done running

###################################################################################################### 
# LOAD FILES
######################################################################################################
#site <- "https://deq1.bse.vt.edu/d.dh/"
site <- "http://deq2.bse.vt.edu/d.dh/"
  
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

#LOAD MAP LAYERS
source(paste(github_location,"/HARParchive/HARP-2020-2021/Cumulative Impact River Mile/CIA_maps.R",sep = '/'))
map_layers <- load_MapLayers(site = site) #WARNING - DO NOT ATTEMPT TO OUTPUT map_layers DIRECTLY TO YOUR CONSOLE, ITS A LIST OF MANY LARGE MAPPING LAYERS
if(!exists("map_layers")) {map_layers <- load_MapLayers(site = "http://deq2.bse.vt.edu/d.dh")} #Load map layers if they're not already loaded in the RStudio environment


# LOAD MAP LAYERS FROM THE map_layers LIST 
STATES <- map_layers[[which(names(map_layers) == "STATES")]]
MinorBasins.csv <- map_layers[[which(names(map_layers) == "MinorBasins.csv")]]
RSeg.csv <- map_layers[[which(names(map_layers) == "RSeg.csv")]]
MajorRivers.csv <- map_layers[[which(names(map_layers) == "MajorRivers.csv")]]
fips.csv <- map_layers[[which(names(map_layers) == "fips.csv")]]
WBDF <- map_layers[[which(names(map_layers) == "WBDF")]]


# #DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
# STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/HARParchive/master/GIS_layers/STATES.tsv', sep = '\t', header = TRUE)
# MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/HARParchive/master/GIS_layers/MinorBasins.csv', sep = ',', header = TRUE)
# 
# #DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
# localpath <- tempdir()
# filename <- paste("vahydro_riversegs_export.csv",sep="")
# destfile <- paste(localpath,filename,sep="\\")
# download.file(paste(site,"vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
# RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
# MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/HARParchive/master/GIS_layers/MajorRivers.csv', sep = ',', header = TRUE)
# 
# #DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
# fips_filename <- paste("vahydro_usafips_export.csv",sep="")
# fips_destfile <- paste(localpath,fips_filename,sep="\\")
# download.file(paste(site,"usafips_centroid_export",sep=""), destfile = fips_destfile, method = "libcurl")
# fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")
# 
#DOWNLOAD IFIM LAYER FROM VAHYDRO
localpath <- tempdir()
ifim_filename <- paste("ifim_transects.csv",sep="")
ifim_destfile <- paste(localpath,ifim_filename,sep="\\")
download.file(paste(site,"ifim_flow_export",sep=""), destfile = ifim_destfile, method = "libcurl")
ifim.csv <- read.csv(file=paste(localpath , ifim_filename,sep="\\"), header=TRUE, sep=",")
# 
# #DOWNLOAD RESERVOIR LAYER FROM LOCAL REPO
# WBDF <- read.table(file=paste(hydro_tools,"GIS_LAYERS","WBDF.csv",sep="/"), header=TRUE, sep=",")

#LOAD RAW mp.all FILE
mp.all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#LOAD MAPPING FUNCTIONS
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.SINGLE.SCENARIO.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/map.divs.R",sep = '/'))

######################################################################################################
### SCENARIO COMPARISONS #############################################################################
######################################################################################################
#----------- RUN SINGLE MAP --------------------------
minorbasin.mapgen(minorbasin = "OR",
                  metric = "l90_Qout",
                  runid_a = "runid_11",
                  runid_b = "runid_13",
                  wd_points = "ON",
                  rsegs = "ON",
                  custom.legend = TRUE,
                  legend_colors = c("#ad6c51","#d98f50","#f7d679","white","#E4FFB9","darkolivegreen3","darkolivegreen4"),
                  legend_divs = c(-20,-10,-1,1,10,20),
                  extent = data.frame(x = c(-80.3, -79.55),
                                      y = c(36.90, 37.65))
                  )



# extent = data.frame(x = c(-80.2, -79.54),
#                     y = c(37.11, 37.429))

#Orig extents- 3.2 between both the xs and both the ys 
# extent <- data.frame(x = c(-80.70709, -77.50709),
#                      y = c(35.40341, 38.60341))





# # minorbasin.mapgen(minorbasin = "YM",
# #                   metric = "l30_Qout",
# #                   runid_a = "runid_11", 
# #                   runid_b = "runid_13",
# #                   wd_points <- "ON",
# #                   rsegs <- "ON")
# minorbasin <- c("OR","OD")
# metric <- c("l30_Qout","l90_Qout","7q10")
# runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
# runid_b <- c("runid_12","runid_13","runid_18")
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
# rsegs <- "ON"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"
# 
# minorbasin <- c("PM","PL")
# metric <- c("l30_cc_Qout", "l90_cc_Qout")
# runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
# runid_b <- c("runid_17","runid_19","runid_20")
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
# rsegs <- "ON"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"
#---------------------------------------------------------------------------------

#----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS (180 figs)
minorbasin <- c("NR", "YP", "TU", "RL", "OR", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
metric <- c("l30_Qout","l90_Qout","7q10")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_12","runid_13","runid_18")
wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
rsegs <- "ON"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"

#NORTHERN BASINS ONLY (FOR CC SCENARIOS) (84 figs)
minorbasin <- c("YP", "RL", "PU", "RU", "YM", "JA", "PM", "YL", "PL", "JU", "JB", "JL","PS","ES")
metric <- c("l30_cc_Qout", "l90_cc_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_17","runid_19","runid_20")
wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
rsegs <- "ON"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"

tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
for (mb in minorbasin) {
  print(paste("PROCESSING MINOR BASIN ",it," OF ",length(minorbasin),": ",mb,sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      minorbasin.mapgen(mb,met,runid_a,rb,wd_points,rsegs,custom.legend = TRUE,
                        legend_colors = c("#ad6c51","#d98f50","#f7d679","white","#E4FFB9","darkolivegreen3","darkolivegreen4"),
                        legend_divs = c(-20,-10,-1,1,10,20)
                        ) 
    } #CLOSE runid FOR LOOP 
  } #CLOSE metric FOR LOOP 
  it <- it + 1
} #CLOSE minorbasin FOR LOOP  
toc()
beep(3)
#------------------------------------------------------------------

######################################################################################################
### SINGLE SCENARIO ##################################################################################
######################################################################################################
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.SINGLE.SCENARIO.R",sep = '/'))
# # #----------- RUN SINGLE MAP --------------------------
minorbasin.mapgen.SINGLE.SCENARIO(minorbasin = "RU",
                                  metric = "consumptive_use_frac",
                                  runid_a = c("runid_13"),
                                  wd_points = "ON",
                                  custom.legend = TRUE)
# 
# minorbasin.mapgen.SINGLE.SCENARIO(minorbasin = "ES",
#                                   metric = "consumptive_use_frac",
#                                   runid_a = c("runid_11"),
#                                   wd_points = "ON")
# 
# minorbasin <- c("PM","PL")
# metric <- "consumptive_use_frac"
# runid_a <- c("runid_11","runid_12","runid_13","runid_18")
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"


#----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS - SINGLE SCENARIO (80 figs)
minorbasin <- c("NR", "YP", "TU", "RL", "OR", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
metric <- "consumptive_use_frac"
runid_a <- c("runid_11","runid_12","runid_13","runid_18")
wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"

#We in fact don't want to use the overall percent of flow change metric with climate change 
# because climate uses that 10 year simulation period, which introduces some odd results. 
# So going forward no need to necessarily generate those figures, and don't need to 
# include those in the statewide results either.
#
#NORTHERN BASINS ONLY (FOR CC SCENARIO) (42 figs)
# minorbasin <- c("YP", "RL", "PU", "RU", "YM", "JA", "PM", "YL", "PL", "JU", "JB", "JL","PS","ES")
# metric <- "consumptive_use_frac"
# runid_a <- c("runid_17","runid_19","runid_20")
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"

tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
for (mb in minorbasin) {
  print(paste("PROCESSING MINOR BASIN ",it," OF ",length(minorbasin),": ",mb,sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_a) {
      print(paste("......PROCESSING runid_a: ",rb,sep=""))
      minorbasin.mapgen.SINGLE.SCENARIO(mb,met,rb,wd_points,custom.legend = TRUE) 
    } #CLOSE runid FOR LOOP 
  } #CLOSE metric FOR LOOP 
  it <- it + 1
} #CLOSE minorbasin FOR LOOP  
toc()
beep(3)
#------------------------------------------------------------------

######################################################################################################
### Well & Intake Location Maps ######################################################################
######################################################################################################
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
# 
# #----------- RUN SINGLE MAP --------------------------
# minorbasin.mapgen(minorbasin = "OR",
#                   metric = "l30_Qout",
#                   runid_a = "runid_11",
#                   runid_b = "runid_13",
#                   wd_points = "ON", #TURN WITHDRAWAL POINTS "ON" OR "OFF"
#                   rsegs = "OFF",     #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"
# )


#----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS - (20 figs)
# minorbasin <- c("NR", "YP", "TU", "RL", "OR", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
# metric <- "l30_Qout"
# runid_a <- "runid_11"
# runid_b <- "runid_13"
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
# rsegs <- "OFF"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"

minorbasin <- c("PM","PL")
metric <- "l30_Qout"
runid_a <- "runid_11"
runid_b <- "runid_13"
wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
rsegs <- "OFF"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"

# minorbasin <- c("NR")
# metric <- "7q10"
# runid_a <- "runid_11"
# runid_b <- c("runid_12","runid_13","runid_18")
# wd_points <- "ON" #TURN WITHDRAWAL POINTS "ON" OR "OFF"
# rsegs <- "ON"    #TURN RSEGS "ON" OR "OFF" - ONLY USED IF wd_points = "ON"

tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
for (mb in minorbasin) {
  print(paste("PROCESSING MINOR BASIN ",it," OF ",length(minorbasin),": ",mb,sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      minorbasin.mapgen(mb,met,runid_a,rb,wd_points,rsegs) 
    } #CLOSE runid FOR LOOP 
  } #CLOSE metric FOR LOOP 
  it <- it + 1
} #CLOSE minorbasin FOR LOOP  
toc()
beep(3)


######################################################################################################
### Well Demand Maps #################################################################################
######################################################################################################
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

#----------- RUN SINGLE MAP --------------------------
# minorbasin.mapgen(minorbasin = "OR",
#                   metric = "l30_Qout",
#                   runid_a = "runid_11", #UNUSED WHEN GENERATING WELL DEMAND MAPS
#                   runid_b = "runid_13", #runid_11, runid_12, or runid_13
#                   wd_points = "ON", #TURN WITHDRAWAL POINTS "ON" FOR PLOTTING WELL DEMANDS
#                   rsegs = "OFF",    #TURN RSEGS "OFF" FOR PLOTTING WELL DEMANDS
#                   wells = "ON"
# )

#----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS - (60 figs)
#minorbasin <- c("NR", "YP", "TU", "RL", "OR", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
minorbasin <- c("PM","PL")
metric <- "l30_Qout" 
runid_a <- "runid_11" 
#runid_b <- "runid_13" 
runid_b <- c("runid_11","runid_12","runid_13")
wd_points <- "ON" 
rsegs <- "OFF"   
wells <- "ON"

tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
for (mb in minorbasin) {
  print(paste("PROCESSING MINOR BASIN ",it," OF ",length(minorbasin),": ",mb,sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      minorbasin.mapgen(mb,met,runid_a,rb,wd_points,rsegs,wells) 
    } #CLOSE runid FOR LOOP 
  } #CLOSE metric FOR LOOP 
  it <- it + 1
} #CLOSE minorbasin FOR LOOP  
toc()
beep(3)
