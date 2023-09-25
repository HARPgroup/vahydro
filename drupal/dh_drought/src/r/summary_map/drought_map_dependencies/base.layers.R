library(sqldf)

#PROCESS BASE LAYERS
base.layers <- function(baselayers,extent = data.frame(x = c(-84, -75),y = c(35.25, 40.6))){
  
  # LOAD MAP LAYERS FROM THE baselayers LIST 
  STATES <- baselayers[[which(names(baselayers) == "STATES")]]
  MajorRivers.csv <- baselayers[[which(names(baselayers) == "MajorRivers.csv")]]
  fips.csv <- baselayers[[which(names(baselayers) == "fips.csv")]]
  
  print(extent)
  ######################################################################################################
  
  # BOUNDING BOX
  bb=readWKT(paste0("POLYGON((",extent$x[1]," ",extent$y[1],",",extent$x[2]," ",extent$y[1],",",extent$x[2]," ",extent$y[2],",",extent$x[1]," ",extent$y[2],",",extent$x[1]," ",extent$y[1],"))",sep=""))
  bbProjected <- SpatialPolygonsDataFrame(bb,data.frame("id"), match.ID = FALSE)
  bbProjected@data$id <- rownames(bbProjected@data)
  bbPoints <- fortify(bbProjected, region = "id")
  bbDF <- merge(bbPoints, bbProjected@data, by = "id")
  
  ######################################################################################################
  ### PROCESS STATES LAYER  ############################################################################
  ######################################################################################################
  
  # NEED TO REMOVE INDIANA DUE TO FAULTY GEOM
  STATES <- sqldf(paste('SELECT * FROM STATES WHERE state != "IN"',sep=""))
  
  STATES$id <- as.numeric(rownames(STATES))
  state.list <- list()
  
  for (i in 1:length(STATES$state)) {
    state_geom <- readWKT(STATES$geom[i])
    state_geom_clip <- gIntersection(bb, state_geom)
    
    if (is.null(state_geom_clip) == TRUE) {
      # print("STATE OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    stateProjected <- SpatialPolygonsDataFrame(state_geom_clip, data.frame('id'), match.ID = TRUE)
    stateProjected@data$id <- as.character(i)
    state.list[[i]] <- stateProjected
  }
  
  length(state.list)
  #REMOVE THOSE STATES THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  state.list <- state.list[which(!sapply(state.list, is.null))]
  length(state.list)
  
  state <- do.call('rbind', state.list)
  state@data <- merge(state@data, STATES, by = 'id')
  state@data <- state@data[,-c(2:3)]
  state.df <- fortify(state, region = 'id')
  state.df <- merge(state.df, state@data, by = 'id') 
  
  ######################################################################################################
  ### PROCESS FIPS LAYER  ##############################################################################
  ######################################################################################################
  
  fips_data <- fips.csv
  length(fips_data[,1])
  fips_data$fips_name
  
  #EXCLUDE NC LOCALITIES
  fips_data_sql <- paste('SELECT *
              FROM fips_data
              WHERE fips_code NOT LIKE "3%"',sep="")
  fips_data <- sqldf(fips_data_sql)
  
  fips_data$id <- as.numeric(rownames(fips_data))
  fips.list <- list()
  
  #f<-1
  for (f in 1:length(fips_data$fips_hydroid)) {
    fips_geom <- readWKT(fips_data$fips_geom[f])
    fips_geom_clip <- gIntersection(bb, fips_geom)
    
    if (is.null(fips_geom_clip) == TRUE) {
      # print("fips OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    fipsProjected <- SpatialPolygonsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    fipsProjected@data$id <- as.character(f)
    fips.list[[f]] <- fipsProjected
  }
  
  length(fips.list)
  #REMOVE THOSE MINOR BASINS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  fips.list <- fips.list[which(!sapply(fips.list, is.null))]
  length(fips.list)
  
  fips <- do.call('rbind', fips.list)
  fips@data <- merge(fips@data, fips_data, by = 'id')
  fips@data <- fips@data[,-c(2:3)]
  fips.df <- fortify(fips, region = 'id')
  fips.df <- merge(fips.df, fips@data, by = 'id') 
  
  
  ######################################################################################################
  ### PROCESS MajorRivers.csv LAYER  ###################################################################
  ######################################################################################################
  rivs_layer <- MajorRivers.csv
  
  riv.centroid.df <-  data.frame(feature=rivs_layer$feature,
                                 GNIS_NAME=rivs_layer$GNIS_NAME,
                                 centroid_longitude="",
                                 centroid_latitude="",
                                 stringsAsFactors=FALSE) 
  
  rivs_layer$id <- rivs_layer$feature
  rivs.list <- list()
  
  #r <- 2
  for (r in 1:length(rivs_layer$feature)) {
    riv_geom <- readWKT(rivs_layer$geom[r])
    
    riv_geom_centroid <- gCentroid(riv_geom,byid=TRUE)
    riv.centroid.df$centroid_longitude[r] <- riv_geom_centroid$x
    riv.centroid.df$centroid_latitude[r] <- riv_geom_centroid$y  
    
    riv_geom_clip <- riv_geom
    
    if (is.null(riv_geom_clip) == TRUE) {
      # print("OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    rivProjected <- SpatialLinesDataFrame(riv_geom_clip, data.frame('id'), match.ID = TRUE)
    rivProjected@data$id <-  as.character(rivs_layer[r,]$id)
    rivs.list[[r]] <- rivProjected
  }
  
  length(rivs.list)
  #REMOVE THOSE rivs_layer THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  rivs.list <- rivs.list[which(!sapply(rivs.list, is.null))]
  length(rivs.list)
  
  rivs <- do.call('rbind', rivs.list)
  rivs@data <- merge(rivs@data, rivs_layer, by = 'id')
  rivs.df <- rivs
  
  baselayers.gg <- list("bb.gg" = bbDF, 
                        "states.gg" = state.df,
                        "fips.gg" = fips.df,
                        "rivs.gg" = rivs.df
  )
  return(baselayers.gg)
  
}

#LOAD BASE LAYERS
load_MapLayers <- function(site,localpath = tempdir()){
  library(ggplot2)
  library(rgeos)
  library(ggsn)
  library(dplyr) # needed for case_when()
  library(sf) # needed for st_read()
  library(sqldf)
  library(ggmap) #used for get_stamenmap, get_map
  
  #DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
  print(paste("DOWNLOADING STATES LAYER DIRECT FROM GITHUB...",sep=""))  
  
  if(!exists("STATES")) {  
    STATES_item <- "https://raw.githubusercontent.com/HARPgroup/HARParchive/master/GIS_layers/STATES.tsv"
    STATES_filename <- "STATES.tsv"
    #file downloaded into local directory, as long as file exists it will not be re-downloaded
    if (file.exists(paste(localpath, STATES_filename, sep = '/')) == FALSE) {
      print(paste("__DOWNLOADING STATES LAYER", sep = ''))
      destfile <- paste(localpath,STATES_filename,sep="\\")
      download.file(STATES_item, destfile = destfile, method = "libcurl")
    } else {
      print(paste("__STATES LAYER PREVIOUSLY DOWNLOADED", sep = ''))
    }
    #read csv from local directory
    print(paste("__LOADING STATES LAYER...", sep = ''))
    STATES <- read.csv(file=paste(localpath,STATES_filename,sep="\\"), header=TRUE, sep="\t")
    print(paste("__COMPLETE!", sep = ''))
  }  
  
  #DOWNLOAD MAJORRIVERS LAYER DIRECT FROM GITHUB
  if(!exists("MajorRivers.csv")) {  
    print(paste("DOWNLOADING MAJORRIVERS LAYER DIRECT FROM GITHUB...",sep=""))
    MajorRivers.csv_item <- "https://raw.githubusercontent.com/HARPgroup/HARParchive/master/GIS_layers/MajorRivers.csv"
    MajorRivers.csv_filename <- "MajorRivers.csv"
    #file downloaded into local directory, as long as file exists it will not be re-downloaded
    if (file.exists(paste(localpath, MajorRivers.csv_filename, sep = '/')) == FALSE) {
      print(paste("__DOWNLOADING MajorRivers.csv LAYER", sep = ''))
      destfile <- paste(localpath,MajorRivers.csv_filename,sep="\\")
      download.file(MajorRivers.csv_item, destfile = destfile, method = "libcurl")
    } else {
      print(paste("__MajorRivers.csv LAYER PREVIOUSLY DOWNLOADED", sep = ''))
    }
    #read csv from local directory
    print(paste("__LOADING MajorRivers.csv LAYER...", sep = ''))
    MajorRivers.csv <- read.csv(file=paste(localpath,MajorRivers.csv_filename,sep="\\"), header=TRUE, sep=",")
    print(paste("__COMPLETE!", sep = ''))  
  }
  
  #DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
  if(!exists("fips.csv")) {  
    print(paste("DOWNLOADING FIPS LAYER DIRECT FROM VAHYDRO...",sep=""))
    fips.csv_item <- paste(site,"/usafips_geom_export",sep="")
    fips.csv_filename <- "fips.csv"
    #file downloaded into local directory, as long as file exists it will not be re-downloaded
    if (file.exists(paste(localpath, fips.csv_filename, sep = '/')) == FALSE) {
      print(paste("__DOWNLOADING fips.csv LAYER", sep = ''))
      destfile <- paste(localpath,fips.csv_filename,sep="\\")
      download.file(fips.csv_item, destfile = destfile, method = "libcurl")
    } else {
      print(paste("__fips.csv LAYER PREVIOUSLY DOWNLOADED", sep = ''))
    }
    #read csv from local directory
    print(paste("__LOADING fips.csv LAYER...", sep = ''))
    fips.csv <- read.csv(file=paste(localpath,fips.csv_filename,sep="\\"), header=TRUE, sep=",")
    print(paste("__COMPLETE!", sep = '')) 
  }
  
  layers <- list("STATES" = STATES, 
                 "MajorRivers.csv" = MajorRivers.csv,
                 "fips.csv" = fips.csv
  )
  return(layers)
}
