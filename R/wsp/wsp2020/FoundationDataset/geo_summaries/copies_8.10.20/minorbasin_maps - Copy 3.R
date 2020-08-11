library(tictoc) #time elapsed
library(beepr) #play beep sound when done running

###################################################################################################### 
# LOAD FILES
######################################################################################################

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
localpath <- tempdir()
filename <- paste("vahydro_riversegs_export.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste("http://deq2.bse.vt.edu/d.dh/vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
#MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)
# river_shp <- readOGR(paste(hydro_tools_location,'/GIS_LAYERS/MajorRivers',sep = ''), "MajorRivers")

#LOAD minorbasin.mapgen()
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))

######################################################################################################
### USER INPUTS  #####################################################################################
######################################################################################################

#----------- RUN SINGLE MAP --------------------------
# PS_sql <- paste('SELECT *
#                         FROM "MinorBasins.csv"
#                         WHERE code = "PS"'
#                        ,sep="")
# PS_layer <- sqldf(PS_sql)
# #write.csv(PS_layer,paste(export_path,"/tables_maps/Xfigures/PS_layer.csv",sep=""), row.names = FALSE)
# 
# MinorBasins.csv <- read.table(file = paste(export_path,"/tables_maps/Xfigures/PS_layer.csv",sep=""), sep = ',', header = TRUE)

minorbasin.mapgen(minorbasin = "PS",
                  metric = "l30_Qout",
                  runid_a = "runid_11",
                  runid_b = "runid_13")




#----------- RUN MAPS IN BULK --------------------------


# minorbasin <- c("PS", "NR", "YP", "TU", "RL", "OR", "EL", "ES", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL")
# metric <- c("7q10", "l30_Qout", "l90_Qout")
# runid_a <- "runid_11"
# runid_b <- c("runid_13","runid_14","runid_15","runid_16","runid_18","runid_17","runid_19","runid_20")


#PROVEN TO RUN
# minorbasin <- c("JL", "JA", "NR")
# metric <- c("l30_Qout")
# runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
# runid_b <- c("runid_13")


minorbasin <- c("NR", "YP", "TU", "RL", "OR", "EL", "PU", "RU", "YM", "JA", "MN", "PM", "YL", "BS", "PL", "OD", "JU", "JB", "JL","PS","ES")
metric <- c("l30_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_13")



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
