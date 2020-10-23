# STATEWIDE VA POP PROJ MAP

library(tictoc) #time elapsed
library(beepr) #play beep sound when done running
library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal) # needed for readOGR()
library(dplyr) # needed for case_when()
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma
library(wicket) #wkt_centroid() 
library(cowplot) #plot static legend
library(magick) #plot static legend
library(ggrepel) #needed for geom_text_repel()
library(ggmap) #used for get_stamenmap, get_map
library(classInt) #used to explicitly determine the breaks
library(stringr)
#library(maps)
#########################################################################################
#LOAD FILES
######################################################################################################
#site <- "https://deq1.bse.vt.edu/d.dh/"
site <- "http://deq2.bse.vt.edu/d.dh/"

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
vapop_folder <- "U:/OWS/foundation_datasets/wsp/Population Data/"


#DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
localpath <- tempdir()
# filename <- paste("vahydro_riversegs_export.csv",sep="")
# destfile <- paste(localpath,filename,sep="\\")
# download.file(paste(site,"vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
# RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
 MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)


# #DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
# fips_filename <- paste("vahydro_usafips_export.csv",sep="")
# fips_destfile <- paste(localpath,fips_filename,sep="\\")
# download.file(paste(site,"usafips_centroid_export",sep=""), destfile = fips_destfile, method = "libcurl")
# fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#DOWNLOAD FIPS GEOM LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_geom_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips_geom.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD RAW mp.all FILE
mp.all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#LOAD MAPPING FUNCTIONS
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.SINGLE.SCENARIO.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))


#---- POPULATION PROJECTION TABLE -------------------------------------------------------------------------------
#vapop <- read.csv("U:\\OWS\\foundation_datasets\\wsp\\Population Data\\VAPopProjections_Total_2020-2040_final.csv")
vapop <- read.csv(paste0(vapop_folder, "VAPopProjections_Total_2020-2040_final.csv"))

vapop <- sqldf('SELECT FIPS, Geography_Name, round(x2020,0), round(x2030,0), round(x2040,0), round(((X2040 - X2020) / X2020)*100, 2) AS pct_change
               FROM vapop')
vapop$Geography_Name <- str_to_title(vapop$Geography_Name)

vapop$Geography_Name <- gsub(x = vapop$Geography_Name, pattern = " County", replacement = "")

# # OUTPUT TABLE IN KABLE FORMAT
# kable(vapop[2:6], align = c('l','c','c','c','c'),format.args = list(big.mark = ","),  booktabs = T, longtable =T,
#       caption = "Virginia Population Projection",
#       label = "VA_pop_proj",
#       col.names = c("Locality",
#                     "2020",
#                     "2030",
#                     "2040",
#                     "20 Year Percent Change")) %>%
#   kable_styling(latex_options = c("striped")) %>%
#   column_spec(1, width = "10em") %>%
#   cat(., file = paste(folder,"tables_maps/Xtables/VA_pop_proj_table.tex",sep=""))


############################################################################################
# MAP #################################################################################
############################################################################################

#statewide.mapgen.POP.PROJ <- function(){
  
  # #CUSTOM DIVS *NOTE* Currently the legend is not dynamic, but a static image
  #good divs for consumptive_use_frac
  div1 <- -25
  div2 <- -10
  div3 <- 0
  div4 <- 5
  div5 <- 10
  div6 <- 25

  color_scale <- c("#ad6c51","#d98f50","#f7d679","darkolivegreen1","darkolivegreen2","darkolivegreen3","darkolivegreen")
  
  # # SELECT MINOR BASIN NAME
  # # mb_name <-sqldf(paste('SELECT name
  # #             FROM "MinorBasins.csv" 
  # #             WHERE code == "',minorbasin,'"',sep=""))
  # # print(paste("PROCESSING: ",mb_name,sep=""))
  mb_name <- data.frame(name = "")
  
  # # RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
  # RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
  # 
  
  ######################################################################################################
  # DETERMINE MAP EXTENT
  # extent <- mb.extent(minorbasin,MinorBasins.csv)
  extent <- data.frame(x = c(-84, -75), y = c(35, 41))
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
  
  ### PROCESS VIRGINIA STATE LAYER  ####################################################################
  va_state <- STATES[STATES$state == 'VA',]
  va_state_sf <- st_as_sf(va_state, wkt = 'geom')
  
  ######################################################################################################
  ### PROCESS Minor Basin LAYER  #######################################################################
  ######################################################################################################
  mb_data <- MinorBasins.csv
  
  # MB_df_sql <- paste('SELECT *
  #             FROM mb_data 
  #             WHERE code = "',minorbasin,'"'
  #                    ,sep="")
  # mb_data <- sqldf(MB_df_sql)
  
  mb_data$id <- as.character(row_number(mb_data$code))
  MB.list <- list()
  
  
  for (z in 1:length(mb_data$code)) {
    MB_geom <- readWKT(mb_data$geom[z])
    MB_geom_clip <- gIntersection(bb, MB_geom)
    MBProjected <- SpatialPolygonsDataFrame(MB_geom_clip, data.frame('id'), match.ID = TRUE)
    MBProjected@data$id <- as.character(z)
    MB.list[[z]] <- MBProjected
  }
  MB <- do.call('rbind', MB.list)
  MB@data <- merge(MB@data, mb_data, by = 'id')
  MB@data <- MB@data[,-c(2:3)]
  MB.df <- fortify(MB, region = 'id')
  MB.df <- merge(MB.df, MB@data, by = 'id')
  
  ######################################################################################################
  ### PROCESS FIPS CENTROID LAYER  #####################################################################
  ######################################################################################################
  
  # # #PADDING TO ENSURE FIPS NAMES DONT GO BEYOND PLOT WINDOW
  # # fips_extent <- data.frame(x = c(extent$x[1]+0.25, extent$x[2]-0.25),
  # #                           y = c(extent$y[1]+0.25, extent$y[2]-0.25))
  # # fips_bb=readWKT(paste0("POLYGON((",fips_extent$x[1]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[1],"))",sep=""))
  # 
  # fips_layer <- fips.csv
  # fips_layer$id <- fips_layer$fips_hydroid
  # fips.list <- list()
  # 
  # for (f in 1:length(fips_layer$fips_hydroid)) {
  #   fips_geom <- readWKT(fips_layer$fips_centroid[f])
  #   fips_geom_clip <- gIntersection(MB_geom, fips_geom) #SHOW ONLY FIPS NAMES WITHIN MINOR BASIN
  #   
  #   if (is.null(fips_geom_clip) == TRUE) {
  #     # print("FIPS OUT OF MINOR BASIN EXTENT - SKIPPING") 
  #     next
  #   }
  #   
  #   fipsProjected <- SpatialPointsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
  #   fipsProjected@data$id <- as.character(fips_layer[f,]$id)
  #   fips.list[[f]] <- fipsProjected
  # }
  # 
  # length(fips.list)
  # #REMOVE THOSE FIPS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  # fips.list <- fips.list[which(!sapply(fips.list, is.null))]
  # length(fips.list)
  # 
  # if (length(fips.list) != 0) {
  #   #  print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT - SKIPPING")
  #   fips <- do.call('rbind', fips.list)
  #   fips@data <- merge(fips@data, fips_layer, by = 'id')
  #   fips@data <- fips@data[,-c(2:3)]
  #   fips_centroid.df <- data.frame(fips)
  # } else {
  #   print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT")
  #   
  #   fips_centroid.df <- data.frame(id=c(1,2),
  #                         fips_latitude =c(1,2), 
  #                         fips_longitude =c(1,2),
  #                         fips_name = c(1,2),
  #                         stringsAsFactors=FALSE) 
  #   
  # }
  # 
  # #print(fips_centroid.df)
  # 
  
  ######################################################################################################
  ### PROCESS FIPS GEOM LAYER  #####################################################################
  ######################################################################################################
  #ATTEMPT NUMBER 154 - 10-19-2020
  
  fips_data <- paste('SELECT *
                  FROM vapop AS a
                  LEFT OUTER JOIN "fips_geom.csv" AS b
                  ON (a.FIPS = b.fips_code)
                  WHERE a.FIPS != 51000
                  ',sep = '')
  fips_layer <- sqldf(fips_data)
  #print(length(fips_data[,1]))
  
  fips_layer$id <- as.character(row_number(fips_layer$fips_hydroid))
  fips.list <- list()
  
  #f <-1
  for (f in 1:length(fips_layer$fips_hydroid)) {
    #print(f)
    fips_geom <- readWKT(fips_layer$fips_geom[f])
    fips_geom_clip <- gIntersection(bb, fips_geom)
    fipsProjected <- SpatialPolygonsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    fipsProjected@data$id <- as.character(f)
    fips.list[[f]] <- fipsProjected
  }
  
  fips <- do.call('rbind', fips.list)
  fips@data <- merge(fips@data, fips_layer, by = 'id')
  fips@data <- fips@data[,-c(2:3)]
  fips.df <- fortify(fips, region = 'id')
  fips_geom.df <- merge(fips.df, fips@data, by = 'id')
  
  
  ############################################################################################################################################################################################################
  
  
  # #ANOTHER ATTEMPT
  # data(county.fips)
  # county.fips[county.fips$fips == 51760,]
  # counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE))
  # counties <- subset(counties, grepl("^virginia", counties$ID))
  # #fips_layer <- merge(fips_layer, vapop, by.x = "fips_code", by.y = "FIPS")
  # counties <- subset(counties, grepl("richmond", counties$ID))
  # 
  # 
  # ggplot(state) + 
  #   geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
  #   #ADD BORDER 
  #   geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  #   geom_sf(data = counties, fill = NA, color = gray(.5))
  #   
  
  ###################################################################################
  # ################################################################################### JK's attempt
  # # fips_layer <- fips_geom.csv
  # # fips_layer <- merge(fips_layer, vapop, by.x = "fips_code", by.y = "FIPS")
  # # fips_layer[1,]
  # # fips_geom.csv[1,]
  # 
  # # colnames(fips_geom.csv)
  # # colnames(vapop)
  # # 
  # # length(fips_geom.csv[,1])
  # # length(vapop[,1])
  # 
  # fips_data <- paste('SELECT *
  #                 FROM vapop AS a
  #                 LEFT OUTER JOIN "fips_geom.csv" AS b
  #                 ON (a.FIPS = b.fips_code)
  #                 WHERE a.FIPS != 51000
  #                 ',sep = '')
  # fips_layer <- sqldf(fips_data)
  # #print(length(fips_data[,1]))
  # 
  # fips_layer$id <- as.character(row_number(fips_layer$fips_hydroid))
  # fips.list <- list()
  # 
  # #f <-1
  # for (f in 1:length(fips_layer$fips_hydroid)) {
  #   #print(f)
  #   fips_geom <- readWKT(fips_layer$fips_geom[f])
  #   fips_geom_clip <- gIntersection(bb, fips_geom)
  #   fipsProjected <- SpatialPolygonsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
  #   fipsProjected@data$id <- as.character(f)
  #   fips.list[[f]] <- fipsProjected
  # }
  # 
  # fips <- do.call('rbind', fips.list)
  # fips@data <- merge(fips@data, fips_layer, by = 'id')
  # fips@data <- fips@data[,-c(2:3)]
  # fips.df <- fortify(fips, region = 'id')
  # fips_geom.df <- merge(fips.df, fips@data, by = 'id')
  # 
  # fips_sf <- st_as_sf(fips, wkt = 'fips_geom')
  # 
  # #THIS SHOW THAT FIPS AT LINE 284 HAS THE WRONG GEOMETRY - GEOMETRY GETS OUT OF ORDER DURING THE LINE 275 FOR LOOP 
  # # plot(state, add = F)
  # # plot(fips, add = T, lwd = 1)
  # # plot(fips_sf)
  # # plot(fips[fips$fips_name == 'Loudoun',], add = T, lwd = 4)
  # # 
  #  #################################
  # # #change from continous variable to discrete - explicit fixed breaks 
  #  breaks_qt <- classIntervals(fips_sf$pct_change, n=7, style="fixed",
  #                  fixedBreaks=c(-50, -25, -10, 0, 5, 10, 25, 60))
  # # #breaks_qt
  # # 
  #   fips_pop_sf <- mutate(fips_sf, pops_pct_change_cat = cut(pct_change, breaks_qt$brks)) 
  # 
  # # #PLOT ALL PCT CHANGE PROJECTIONS
  # ggplot(fips_pop_sf) +
  #   geom_sf(aes(fill=pops_pct_change_cat, geometry = geometry)) +
  #   scale_fill_brewer(palette = "PuOr")
  # 
  # # #CAN CLEARLY SEE LOUDOUN IS IN SMYTH'S LOCATION (BRIGHT YELLOW; HIGHEST PROJECTION CHANGE = 55%)
  # #   plot(fips_pop_sf$pct_change)
  # #   plot(fips_pop_sf["pct_change"])
  #   
  #   
  #   # #SPECIFICALLY PLOT JUST LOUDOUN TO SEE WHERE IT IS
  #   loud_fips_sf <- filter(fips_sf, fips_name == "Loudoun")
  #   
  #   
  #   map.test <- ggplot(fips_pop_sf) +
  #     
  #        geom_sf(aes(fill=pops_pct_change_cat, geometry = geometry)) +
  #        scale_fill_brewer(palette = "PuOr") +
  #   
  #   geom_label_repel(data = loud_fips_sf, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),size = 1.75, color = "black", fill = "white", xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))
  #   
  #   ggsave(plot = map.test, file =  paste0(folder, "JM_VA_pop_proj_map_TEST.png"), width=6.5, height=5)                  
  # 
  #    # geom_sf(data = loud_fips_sf,aes(geometry = fips_centroid), fill = "black", inherit.aes = F) +
  #    #  geom_sf_text(data = loud_fips_sf,aes(geometry = fips_centroid,label = fips_name), color = 'blue', inherit.aes = F)
  # 
  # 
  #   
  #   
  #   
    # ##################################
    # #SUBSET OUT JUST 3 COUNTIES
    # ##################################
    # fips_layer <- fips_geom.csv
    # fips_layer <- merge(fips_layer, vapop, by.x = "fips_code", by.y = "FIPS")
    # fips_layer <- fips_layer[fips_layer$fips_name %in% c('Virginia Beach','Bath','Loudoun'),]
    # #fips_layer <- fips_layer[1:10,]
    # 
    # 
    # fips_layer$id <- as.character(row_number(fips_layer$fips_hydroid))
    # fips.list <- list()
    # 
    # for (f in 1:length(fips_layer$fips_hydroid)) {
    #   fips_geom <- readWKT(fips_layer$fips_geom[f])
    #   fips_geom_clip <- gIntersection(bb, fips_geom)
    #   if (is.null(fips_geom_clip) == TRUE) {
    #     # print("FIPS OUT OF BOUNDING BOX EXTENT - SKIPPING") 
    #     next
    #   }
    #   fipsProjected <- SpatialPolygonsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    #   fipsProjected@data$id <- as.character(fips_layer[f,]$id)
    #   fips.list[[f]] <- fipsProjected
    # }
    # 
    # length(fips.list)
    # #REMOVE THOSE FIPS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
    # fips.list <- fips.list[which(!sapply(fips.list, is.null))]
    # length(fips.list)
    # fips <- do.call('rbind', fips.list)
    # fips@data <- merge(fips@data, fips_layer, by = 'id')
    # fips@data <- fips@data[,-c(2:3)]
    # fips.df <- fortify(fips, region = 'id')
    # fips_geom.df <- merge(fips.df, fips@data, by = 'id')
    # 
    # fips_sf <- st_as_sf(fips, wkt = 'fips_geom')
    # 
    # #JUST SUBSETTING OUT 3 COUNTIES - ALL 3 ARE IN THEIR CORRECT LOCATION
    # plot(state, add = F)
    # plot(fips, add = T, lwd = 1)
    # plot(fips[fips$fips_name == 'Bath',], add = T, lwd = 4)
    # # print(fips_geom.df)
    # breaks_qt <- classIntervals(fips_sf$pct_change, n=7, style="fixed",
    #                             fixedBreaks=c(-50, -25, -10, 0, 5, 10, 25, 60))
    # #breaks_qt
    # 
    # fips_pop_sf <- mutate(fips_sf, pops_pct_change_cat = cut(pct_change, breaks_qt$brks))
    # 
    # loud_fips_sf <- filter(fips_sf, fips_name == "Loudoun")
    # ggplot(fips_pop_sf) +
    #   geom_sf(aes(fill=pops_pct_change_cat, geometry = geometry)) +
    #   scale_fill_brewer(palette = "PuOr") +
    #   geom_sf(data = loud_fips_sf,aes(geometry = geometry), fill = "black", inherit.aes = F) +
    #   geom_sf_text(data = loud_fips_sf,aes(label = fips_name), color = 'blue', inherit.aes = F)
  ######################################################################################################
  ### PROCESS MajorRivers.csv LAYER  ###################################################################
  ######################################################################################################
  rivs_layer <- MajorRivers.csv
  
  # rivs_layer_sql <- paste('SELECT *
  #             FROM rivs_layer
  #             WHERE GNIS_NAME = "New River" OR GNIS_NAME = "South Fork New River"'
  #                         ,sep="")
  # rivs_layer <- sqldf(rivs_layer_sql)
  
  #------------------------------------------------------------
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
    
    
    # riv_geom_clip <- gIntersection(MB_geom, riv_geom)
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
  #print(class(rivs.df))
  #plot(rivs, add = T, col = 'blue')
  #print(riv.centroid.df)
  ######################################################################################################
  ### PROCESS mp.all LAYER  ############################################################################
  ######################################################################################################
  #   mp_layer  <- mp.all 
  #   
  #   # #REMOVE POWER
  #   mp_layer_nohydro <- paste("SELECT *
  #                   FROM mp_layer
  #                   WHERE facility_ftype NOT LIKE '%power%'")
  #                   #WHERE facility_ftype != 'hydropower'")
  #   mp_layer <- sqldf(mp_layer_nohydro)
  #   
  #   mp_layer$mp_exempt_mgy <- mp_layer$final_exempt_propvalue_mgd*365.25
  #   demand_query_param <-case_when(runid_b == "runid_12" ~ "mp_2030_mgy",
  #                                  runid_b == "runid_13" ~ "mp_2040_mgy",
  #                                  runid_b == "runid_14" ~ "mp_2020_mgy",
  #                                  runid_b == "runid_15" ~ "mp_2020_mgy",
  #                                  runid_b == "runid_16" ~ "mp_2020_mgy",
  #                                  runid_b == "runid_17" ~ "mp_2040_mgy",
  #                                  runid_b == "runid_18" ~ "mp_exempt_mgy",
  #                                  runid_b == "runid_19" ~ "mp_2040_mgy",
  #                                  runid_b == "runid_20" ~ "mp_2040_mgy")
  #   
  #   #mp_layer_sql <- paste('SELECT *, round(',demand_query_param,'/365.25,3) AS demand_metric
  #   mp_layer_sql <- paste('SELECT *, ',demand_query_param,'/365.25 AS demand_metric
  #                          FROM mp_layer 
  #                          WHERE MinorBasin_Code = "',minorbasin,'"'
  #                         ,sep="")
  #   mp_layer <- sqldf(mp_layer_sql)
  #   
  #   #DIVISIONS IN MGD
  #   div <- c(0.5,1.0,2.0,5.0,10,25,50,100,1000)
  #   bins_sql <-  paste("SELECT *,
  # 	                  CASE WHEN demand_metric <= ",div[1]," THEN '1'
  # 		                WHEN demand_metric >  ",div[1]," AND demand_metric <= ",div[2]," THEN '2'
  # 		                WHEN demand_metric >  ",div[2]," AND demand_metric <= ",div[3]," THEN '3'
  # 		                WHEN demand_metric >  ",div[3]," AND demand_metric <= ",div[4]," THEN '4'
  # 		                WHEN demand_metric >  ",div[4]," AND demand_metric <= ",div[5]," THEN '5'
  # 		                WHEN demand_metric > ",div[5]," AND demand_metric <= ",div[6]," THEN '6'
  # 		                WHEN demand_metric > ",div[6]," AND demand_metric <= ",div[7]," THEN '7'
  # 		                WHEN demand_metric > ",div[7]," AND demand_metric <= ",div[8]," THEN '8'
  # 		                WHEN demand_metric > ",div[8]," AND demand_metric <= ",div[9]," THEN '9'
  # 		                WHEN demand_metric > ",div[9]," THEN '10'
  # 		                ELSE 'X'
  # 		                END AS bin
  # 		                FROM mp_layer",sep="")
  #   mp_layer <- sqldf(bins_sql)
  #   
  #   well_layer_sql <- paste('SELECT *
  #               FROM mp_layer 
  #               WHERE MP_bundle = "well"'
  #                           ,sep="")
  #   well_layer <- sqldf(well_layer_sql)
  #   # well.max <- max(well_layer$mp_2040_mgy)
  #   # well.min <- min(well_layer$mp_2040_mgy)
  #   # well.range <- paste("Well WD: ",well.min/365.25," to ",round(well.max/365.25,3)," mgd",sep="")
  # 
  #   well_bin_1 <-   sqldf('SELECT * FROM well_layer WHERE bin = 1')
  #   well_bin_2 <-   sqldf('SELECT * FROM well_layer WHERE bin = 2')
  #   well_bin_3 <-   sqldf('SELECT * FROM well_layer WHERE bin = 3')
  #   well_bin_4 <-   sqldf('SELECT * FROM well_layer WHERE bin = 4')
  #   well_bin_5 <-   sqldf('SELECT * FROM well_layer WHERE bin = 5')
  #   well_bin_6 <-   sqldf('SELECT * FROM well_layer WHERE bin = 6')
  #   well_bin_7 <-   sqldf('SELECT * FROM well_layer WHERE bin = 7')
  #   well_bin_8 <-   sqldf('SELECT * FROM well_layer WHERE bin = 8')
  #   well_bin_9 <-   sqldf('SELECT * FROM well_layer WHERE bin = 9')
  #   well_bin_10 <-  sqldf('SELECT * FROM well_layer WHERE bin = 10')
  #   
  #   intake_layer_sql <- paste('SELECT *
  #               FROM mp_layer 
  #               WHERE MP_bundle = "intake"
  #               ORDER BY mp_2040_mgy ASC'
  #                             ,sep="")
  #   intake_layer <- sqldf(intake_layer_sql)
  #   # intake.max <- max(intake_layer$mp_2040_mgy)
  #   # intake.min <- min(intake_layer$mp_2040_mgy)
  #   # intake.range <- paste("Intake WD Range: ",intake.min/365.25," to ",round(intake.max/365.25,3)," mgd",sep="")
  #   
  #   intake_bin_1 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 1')
  #   intake_bin_2 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 2')
  #   intake_bin_3 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 3')
  #   intake_bin_4 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 4')
  #   intake_bin_5 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 5')
  #   intake_bin_6 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 6')
  #   intake_bin_7 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 7')
  #   intake_bin_8 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 8')
  #   intake_bin_9 <-   sqldf('SELECT * FROM intake_layer WHERE bin = 9')
  #   intake_bin_10 <-  sqldf('SELECT * FROM intake_layer WHERE bin = 10')
  #   
  #   # if (length(intake_bin_10$bin) > 0){
  #   #   print("Intakes in bin 10")
  #   #   beep(2)
  #   #   }
  #   
  ######################################################################################################
  ### PROCESS RSegs
  ######################################################################################################
  # JOIN DATA BY RIVER SEGMENT TO RIVER SEGMENT GEOMETRY LAYER
  # RSeg_data <- paste('SELECT *
  #                 FROM "RSeg.csv" AS a
  #                 LEFT OUTER JOIN RSeg_summary AS b
  #                 ON (a.hydrocode = b.hydrocode)
  #                 ',sep = '')  
  # # WHERE a.hydrocode LIKE "%wshed_',minorbasin,'%"',sep = '') 
  # 
  # RSeg_data <- sqldf(RSeg_data)
  # 
  # #print(length(RSeg_data[,1]))
  # 
  # # NEED TO REMOVE SECOND "hydrocode" COLUMN TO PREVENT ERROR LATER ON
  # RSeg_data <- RSeg_data[,-which(colnames(RSeg_data)=="hydrocode" )[2]]
  # 
  # # REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
  # RSeg_valid_geoms <- paste("SELECT *
  #                 FROM RSeg_data
  #                 WHERE geom != ''")  
  # RSeg_data <- sqldf(RSeg_valid_geoms)
  # #print(length(RSeg_data[,1]))
  # 
  # #PL_hcodes <<- RSeg_data[,1:5]
  # 
  # 
  # # USE THIS TO REMOVE ANY "_0000" TIDAL SEGMENTS - THEY WILL APPEAD AS GAPS ON THE MAP
  # # RSeg_non_tidal <- paste("SELECT *
  # #                 FROM RSeg_data
  # #                 WHERE hydrocode NOT LIKE '%_0000'")
  # # RSeg_data <- sqldf(RSeg_non_tidal)
  # # print(length(RSeg_data[,1]))
  
  ######################################################################################################
  ### PLOTTING TITLES  #################################################################################
  ######################################################################################################
  # SELECT PLOT TITLE BASED ON CHOSEN METRIC
  # metric_title <- case_when(metric == "l30_Qout" ~ "30 Day Low Flow",
  #                           metric == "l90_Qout" ~ "90 Day Low Flow",
  #                           metric == "7q10" ~ "7Q10",
  #                           metric == "l30_cc_Qout" ~ "30 Day Low Flow",
  #                           metric == "l90_cc_Qout" ~ "90 Day Low Flow",
  #                           metric == "wd_cumulative_mgd" ~ "Cumulative Upstream Demand (mgd)",
  #                           metric == "consumptive_use_frac" ~ "Overall Percent of Flow Change")
  # # metric == "consumptive_use_frac" ~ "Percent Consumptive Use")
  # 
  # # SELECT PLOT TITLE BASED ON CHOSE SCENARIOS
  # scenario_title <- case_when(runid_a == "runid_11" ~ "2020",
  #                             runid_a == "runid_12" ~ "2030",
  #                             runid_a == "runid_13" ~ "2040",
  #                             runid_a == "runid_14" ~ "Med Climate Change",
  #                             runid_a == "runid_15" ~ "Dry Climate Change",
  #                             runid_a == "runid_16" ~ "Wet Climate Change",
  #                             runid_a == "runid_17" ~ "Dry Climate Change",
  #                             runid_a == "runid_18" ~ "Exempt Users",
  #                             runid_a == "runid_19" ~ "Med Climate Change",
  #                             runid_a == "runid_20" ~ "Wet Climate Change")
  # 
  # 
  # ### PROCESS Southern Rivers basins (no Climate Change model runs) LAYER  #######################################################################
  # if (runid_a  %in% c('runid_14','runid_15','runid_16','runid_17','runid_19','runid_20')) {
  #   #subset
  #   RSeg_southern_basins <- sqldf("SELECT * 
  #                               FROM RSeg_data
  #                               WHERE hydrocode LIKE 'vahydrosw_wshed_BS%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_TU%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_NR%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_OR%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_OD%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_MN%'
  #                               OR hydrocode LIKE 'vahydrosw_wshed_KU0_8980_0000'
  #                               ")
  #   #convert to spatial object
  #   RSeg_southern_basins_sf <- st_as_sf(RSeg_southern_basins, wkt = 'geom')
  #   #geom_sf to plot object
  #   RSeg_southern_b_geom <- geom_sf(data = RSeg_southern_basins_sf,aes(geometry = geom),fill = 'gray30',color = 'gray30', inherit.aes = FALSE)
  #   #annotation rectangle + text
  #   cc_models_box <- annotate("rect", xmin = extent$x[1]+ 3.05, xmax = extent$x[1]+4.8, ymin = extent$y[1]+1.68, ymax = extent$y[1]+2.1, color = 'black', fill = 'gray30', lwd = .4 )
  #   #annotate text
  #   cc_models_text <- annotate("text", x = extent$x[1]+3.9, y = extent$y[1]+1.9, label = "Climate Models to be \n developed prior to 2023", size = 2.5, color = 'snow')
  #   
  # } else {
  #   RSeg_southern_b_geom <- geom_blank()
  #   cc_models_box <- geom_blank()
  #   cc_models_text <- geom_blank()
  # }
  # 
  
  ######################################################################################################
  ### GENERATE MAPS  ###################################################################################
  ######################################################################################################
  
  print(paste("RETRIEVING BASEMAP:",sep=""))
  
  tile_layer <- get_map(
    location = c(left = extent$x[1],
                 bottom = extent$y[1],
                 right = extent$x[2],
                 top = extent$y[2]),
    source = "osm", zoom = 9, maptype = "satellite" #good
  )
  
  base_layer <- ggmap(tile_layer)
  
  base_map <- base_layer + 
    #geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
    geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)
  
  # base_scale <-  ggsn::scalebar(data = bbDF, location = 'bottomleft', dist = 25, dist_unit = 'mi', 
  #                               transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
  #                               st.size = 3, st.dist = 0.03,
  #                               anchor = c(
  #                                 x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-0.45,
  #                                 y = extent$y[1]+(extent$y[1])*0.001
  #                               ))
  
  base_scale <- ggsn::scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'mi',
                               transform = TRUE, model = 'WGS84',st.bottom=FALSE,
                               st.size = 3.5, st.dist = 0.0285,
                               anchor = c(
                                 x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-1.8,
                                 y = extent$y[1]+(extent$y[1])*0.001
                               ))
  
  
  base_theme <- theme(legend.justification=c(0,1), 
                      legend.position="none",
                      
                      # plot.margin = unit(c(0.5,-0.2,0.25,-3), "cm"),
                      plot.title = element_text(size=12),
                      plot.subtitle = element_text(size=10),
                      
                      axis.title.x=element_blank(),
                      axis.text.x=element_blank(),
                      axis.ticks.x=element_blank(),
                      axis.title.y=element_blank(),
                      axis.text.y=element_blank(),
                      axis.ticks.y=element_blank(),
                      panel.grid.major = element_blank(), 
                      panel.grid.minor = element_blank(),
                      panel.background = element_blank(),
                      panel.border = element_blank())
  
  #color_scale_original <- c("darkolivegreen3","cornflowerblue","khaki2","plum3","coral3")
  #color_scale_new <- c("white","navajowhite","sandybrown","#ad6c51","#754b39","gray55")
  
  #SELECT LEGEND IMAGE PATH (WITH OR WITHOUT TIDAL SEGMENT)
  # if (minorbasin %in% c('JA','PL','RL','YL','YM','YP','EL','JB','MN','ES')) {
  #   image_path <- paste(folder, 'tables_maps/legend_rseg_tidal_segment.PNG',sep='')
  # } else {
  #   image_path <- paste(folder, 'tables_maps/legend_rseg.PNG',sep='')
  # }
  #image_path <- paste(folder, 'tables_maps/legend_rseg_tidal_segment_padding.PNG',sep='')
  
  #image_path <- paste(folder, 'tables_maps/legend_rseg_SINGLE_tidal_segment_padding.PNG',sep='')
  
  # base_legend <- draw_image(image_path,height = .282, x = 0.395, y = .6) #RIGHT TOP LEGEND
  #base_legend <- draw_image(image_path,height = .4, x = -0.359, y = .47) #LEFT TOP LEGEND
  
  # deqlogo <- draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1,  x = -.384, y = 0.32) #LEFT TOP LOGO
  #deqlogo <- draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1, x = -.388, y = -0.402) #LEFT BOTTOM LOGO
  ######################################################################################################
  #VA POP PCT CHANGE - BREAK INTO BINS
  
  c_border <- 'black'

  group_neg25 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change <= ",div1)
  group_neg25 <- sqldf(group_neg25)
  group_neg25 <- st_as_sf(group_neg25, wkt = 'fips_geom')

  color_values <- list()
  label_values <- list()

  if (nrow(group_neg25) >0) {

    geom1 <- geom_sf(data = group_neg25, fill = color_scale[1],color = c_border, inherit.aes = FALSE)

    color_values <- color_scale[1]

    label_values <- paste(" <= ",div1,sep="")

  } else  {

    geom1 <- geom_blank()

  }
  # #-----------------------------------------------------------------------------------------------------
  group_neg25_10 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div1," AND pct_change <= ",div2)
  group_neg25_10 <- sqldf(group_neg25_10)
  group_neg25_10 <- st_as_sf(group_neg25_10, wkt = 'fips_geom')
  
  
  if (nrow(group_neg25_10) >0) {
    
    geom2 <- geom_sf(data = group_neg25_10,fill = color_scale[2],color = c_border, inherit.aes = FALSE)
    
      color_values <- rbind(color_values,color_scale[2])
      label_values <- rbind(label_values,paste(div1," to ",div2,sep=""))
    
  } else  {
    
    geom2 <- geom_blank()
    
  }
  # #-----------------------------------------------------------------------------------------------------
  group_neg10_0 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div2," AND pct_change <= ",div3)
  group_neg10_0 <- sqldf(group_neg10_0)
  group_neg10_0 <- st_as_sf(group_neg10_0, wkt = 'fips_geom')
  
  
  if (nrow(group_neg10_0) >0) {
    
    geom3 <- geom_sf(data = group_neg10_0, fill = color_scale[3],color = c_border, inherit.aes = FALSE)
    
    color_values <- rbind(color_values,color_scale[3])
    label_values <- rbind(label_values,paste(div2," to ",div3,sep=""))
    
  } else  {
    
    geom3 <- geom_blank()
    
  }
  # #-----------------------------------------------------------------------------------------------------
  group_0_5 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div3," AND pct_change <= ",div4)
  group_0_5 <- sqldf(group_0_5)
  group_0_5 <- st_as_sf(group_0_5, wkt = 'fips_geom')
  
  
  if (nrow(group_0_5) >0) {
    
    geom4 <- geom_sf(data = group_0_5, fill = color_scale[4],color = c_border, inherit.aes = FALSE)
    
    color_values <- rbind(color_values,color_scale[4])
    label_values <- rbind(label_values,paste(div3," to ",div4,sep=""))
    
  } else  {
    
    geom4 <- geom_blank()
    
  }
  # #-----------------------------------------------------------------------------------------------------
  group_5_10 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div4," AND pct_change <= ",div5)
  group_5_10 <- sqldf(group_5_10)
  group_5_10 <- st_as_sf(group_5_10, wkt = 'fips_geom')
  
  
  if (nrow(group_5_10) >0) {
    
    geom5 <- geom_sf(data = group_5_10, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
    
    color_values <- rbind(color_values,color_scale[5])
    label_values <- rbind(label_values,paste(div4," to ",div5,sep=""))
    
  } else  {
    
    geom5 <- geom_blank()
    
  }
  # #-----------------------------------------------------------------------------------------------------
  group_10_25 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div5," AND pct_change <= ",div6)
  group_10_25 <- sqldf(group_10_25)
  group_10_25 <- st_as_sf(group_10_25, wkt = 'fips_geom')
  
  
  if (nrow(group_10_25) >0) {
    
    geom6 <- geom_sf(data = group_10_25, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
    
    color_values <- rbind(color_values,color_scale[5])
    label_values <- rbind(label_values,paste(div5," to ",div6,sep=""))
    
  } else  {
    
    geom6 <- geom_blank()
    
  }
  # #-----------------------------------------------------------------------------------------------------
  group_plus25 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change >= ",div6)
  group_plus25 <- sqldf(group_plus25)
  group_plus25 <- st_as_sf(group_plus25, wkt = 'fips_geom')
  
  
  if (nrow(group_plus25) >0) {
    
    geom7 <- geom_sf(data = group_plus25, fill = color_scale[7],color = c_border, inherit.aes = FALSE)
    
    color_values <- rbind(color_values,color_scale[6])
    label_values <- rbind(label_values,paste(" >= ",div5,sep=""))
    
  } else  {
    
    geom7 <- geom_blank()
    
  }
  # #---------------------------------------------------------------
  # # DATAFRAME OF ANY "_0000" TIDAL SEGMENTS
  # # RSeg_tidal <- paste("SELECT *
  # #                 FROM RSeg_data
  # #                 WHERE hydrocode LIKE '%_0000'")
  # # RSeg_tidal <- sqldf(RSeg_tidal)
  # 
  # RSeg_tidal <- paste("SELECT *
  #                 FROM RSeg_data
  #                 WHERE hydrocode LIKE 'vahydrosw_wshed_JA%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_PL%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_RL%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_YL%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_YM%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_YP%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_EL%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_JB%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_MN%_0000' OR
  #                       hydrocode LIKE 'vahydrosw_wshed_ES%_0000'
  #                     ")
  # RSeg_tidal <- sqldf(RSeg_tidal)
  # 
  # if ((length(RSeg_tidal[,1]) >= 1) == TRUE) {
  #   
  #   group_tidal_base <- st_as_sf(RSeg_data, wkt = 'geom')
  #   geom_tidal_base <- geom_sf(data = group_tidal_base,aes(geometry = geom,fill = color_scale[6],colour=rseg_border), inherit.aes = FALSE, show.legend = FALSE)
  #   
  #   
  #   group_tidal <- st_as_sf(RSeg_tidal, wkt = 'geom')
  #   geom_tidal <- geom_sf(data = group_tidal,aes(geometry = geom,fill = color_scale[6],colour=rseg_border), inherit.aes = FALSE, show.legend = FALSE)
  #   color_values <- rbind(color_values,color_scale[6])
  #   label_values <- rbind(label_values,"Tidal Segment")
  #   
  # } else  {
  #   
  #   if(exists(x = 'group_tidal')){rm(group_tidal)}
  #   geom_tidal_base <- geom_blank()
  #   geom_tidal <- geom_blank()
  #   
  # }
  
  
  ####################################################################
  source_current <- base_map +
    # geom_tidal_base +
    geom1 +
    geom2 +
    geom3 +
    geom4 +
    geom5 +
    geom6 +
    geom7 
    # scale_fill_manual(values=color_values,
    #                    name = "Legend",
    #                    labels = label_values)+
    # scale_colour_manual(values="black")+
    # guides(fill = guide_legend(reverse=TRUE))
  
  
     ggsave(plot = source_current, file =  paste0(folder, "JM_VA_pop_proj_map_TEST3.png"), width=6.5, height=5) 
  
  
  #ADD TIDAL RSEGS LAYER ON TOP FOR THOSE MINOR BASINS THAT HAVE TIDAL RSEGS
  # *note, if the following if statement was removed and geom_tidal layer still 
  #     added on top, the resulting maps will be 100% identical to the vahydro mapserv maps
  #     i.e. minor basins such as TU will have _0000 rsegs greyed out (but thats yucky)
  # if (minorbasin %in% c('JA','PL','RL','YL','YM','YP','EL','JB','MN','ES')) {
  #   source_current <- source_current + geom_tidal
  # }
  
  # source_current <- source_current + geom_tidal
  
  #EXPORT FILE NAME FOR MAP PNG
  # export_file <- paste0(export_path, "tables_maps/Xfigures/",minorbasin,"_",runid_a,"_to_",runid_b,"_",metric,"_map.png",sep = "")
  #export_file <- paste0(export_path, "tables_maps/Xfigures/VA_",runid_a,"_to_",runid_b,"_",metric,"_map.png",sep = "")
  
  #metric first makes it easier to page through comparisons
  # export_file <- paste0(export_path, "tables_maps/Xfigures/VA_",metric,"_",runid_a,"_to_",runid_b,"_map.png",sep = "")
  #export_file <- paste0(export_path, "tables_maps/Xfigures/VA_pop_proj_map.png",sep = "")
  export_file <- paste0(folder, "VA_pop_proj_map.png")
  
  # if (wd_points == "OFF") {
  #   print("PLOTTING - WITHDRAWAL POINTS OFF") 
  
  map <- source_current +
                  
                  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = "snow",alpha = .5,lwd=0.8) +
                  
                  geom_sf(data = fips_sf, aes(fill = pct_change), color="snow", lwd = .7, inherit.aes = FALSE)+
                 geom_label_repel(data = fips_sf, aes(x = fips_longitude, y = fips_latitude, group = 1, label = pct_change),size = 1.75, color = "black", fill = "white", xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
 
                  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.8) +
                  
                  ggtitle("Virginia Population Projection") +
                  labs(subtitle = "2020 to 2040 Percent Change") +
                  
                  #ADD STATE BORDER LAYER ON TOP
                  geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
                  #ADD RIVERS LAYER ON TOP
                  geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
                  #ADD BORDER 
                  geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
                  
                  #cc_models_box +
                  #cc_models_text +
                  
                  #ADD RIVER POINTS
                  #geom_point(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1),size =1, shape = 20, fill = "black")+
                  #ADD RIVER LABELS
                  # geom_text_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 2, color = "dodgerblue3")+
                  #geom_label_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 1.75, color = "dodgerblue3", fill = NA, xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
                  
                  #ADD FIPS POINTS
                  # geom_point(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1),
                  #            size =1, shape = 20, fill = "black")+
                  # #ADD FIPS LABELS
                 #geom_text_repel(data = fips_geom.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name), size = 2)+
                #ADD WHITE VA STATE BORDER ON TOP
                #geom_sf(data = va_state_sf, fill = NA, color="white", lwd = 1.2, inherit.aes = FALSE)+
                  
                  #ADD NORTH BAR
                  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                  base_scale +
                  base_theme
  
  map
  
  # } else if (wd_points == "ON") {
  #   print("PLOTTING - WITHDRAWAL POINTS ON") 
  #   
  #   base_theme <- theme(legend.title = element_text(size = 7.4),
  #     legend.position=c(1.137, .4), #USE TO PLACE LEGEND TO THE RIGHT OF MAP
  #     # plot.margin = unit(c(0.5,-0.2,0.25,-3), "cm"),
  #     plot.title = element_text(size=12),
  #     plot.subtitle = element_text(size=10),
  #     
  #     axis.title.x=element_blank(),
  #     axis.text.x=element_blank(),
  #     axis.ticks.x=element_blank(),
  #     axis.title.y=element_blank(),
  #     axis.text.y=element_blank(),
  #     axis.ticks.y=element_blank(),
  #     panel.grid.major = element_blank(), 
  #     panel.grid.minor = element_blank(),
  #     panel.background = element_blank(),
  #     panel.border = element_blank())
  #   
  #   if (rsegs == "ON") {
  # 
  #     # LEGEND SETUP
  #     if (legend_b_title == "2030") {
  #       bubble_legend <- paste(folder, 'tables_maps/bubble_legend_2030_short.PNG',sep='')
  #     } else if  (legend_b_title == "2040") {
  #       bubble_legend <- paste(folder, 'tables_maps/bubble_legend_2040_short.PNG',sep='')
  #     } else if  (legend_b_title == "Exempt") {
  #       bubble_legend <- paste(folder, 'tables_maps/bubble_legend_exempt_short.PNG',sep='')
  #     }
  #     
  #     bubble_legend <- draw_image(bubble_legend,height = .5, x = 0.395, y = 0.04) 
  #     
  #     map <- ggdraw(source_current +
  #                     geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.7) +
  #                     ggtitle(paste(metric_title," (Percent Change ",scenario_a_title," to ",scenario_b_title,")",sep = '')) +
  #                     labs(subtitle = mb_name$name) +
  #                     #ADD STATE BORDER LAYER ON TOP
  #                     geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
  #                     #ADD RIVERS LAYER ON TOP
  #                     geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
  # 
  #                     #ADD BORDER 
  #                     geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  #                     
  #                     #ADD RIVER POINTS
  #                     #geom_point(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1),size =1, shape = 20, fill = "black")+
  #                     #ADD RIVER LABELS
  #                     geom_text_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 2, color = "dodgerblue3")+
  #                     #geom_label_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 1.75, color = "dodgerblue3", fill = NA, xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
  #                     
  #                     #ADD FIPS POINTS
  #                     geom_point(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1),
  #                                size =1, shape = 20, fill = "black")+
  #                     #ADD FIPS LABELS
  #                      geom_text_repel(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),
  #                                       size = 2)+
  #                     #geom_label_repel(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),size = 1.75, color = "black", fill = "white", xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
  #                     
  #                     # #ADD WITHDRAWAL LOCATIONS ON TOP (ALL MPS) #corrected_longitude, corrected_latitude
  #                     # #---------------------------------------------------------------
  #                     # geom_point(data = intake_bin_1, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 1, alpha = 0.3) +
  #                     # geom_point(data = intake_bin_2, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 2, alpha = 0.4) +
  #                     # geom_point(data = intake_bin_3, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 3, alpha = 0.5) +
  #                     # geom_point(data = intake_bin_4, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 4, alpha = 0.6) +
  #                     # geom_point(data = intake_bin_5, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 5, alpha = 0.7) +
  #                     # geom_point(data = intake_bin_6, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 6, alpha = 0.8) +
  #                     # geom_point(data = intake_bin_7, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 7, alpha = 0.9) +
  #                     # geom_point(data = intake_bin_8, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 8, alpha = 0.95) +
  #                     # geom_point(data = intake_bin_9, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 9, alpha = 0.975) +
  #                     # geom_point(data = intake_bin_10, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 10, alpha = 1.0) +
  #                     # #---------------------------------------------------------------
  #                     
  #                     #ADD NORTH BAR
  #                     north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  #                     base_scale +
  #                     base_theme) +
  #       base_legend +
  #       # bubble_legend +
  #       deqlogo
  #   } else if (rsegs == "OFF") {
  #     print("PLOTTING - RIVERSEGS TURNED OFF") 
  #     #EXPORT FILE NAME FOR MAP PNG
  #     # export_file <- paste0(export_path, "tables_maps/Xfigures/",minorbasin,"_Withdrawa_Locations_",legend_b_title,"_map.png",sep = "")
  #     export_file <- paste0(export_path, "tables_maps/Xfigures/",minorbasin,"_Withdrawal_Locations_map.png",sep = "")
  #     
  #     SourceTypeLegend <- paste(folder, 'tables_maps/SourceTypeLegend.PNG',sep='')
  #     SourceTypeLegend <- draw_image(SourceTypeLegend,height = .26, x = 0.39, y = .6)
  #     
  #     # if (legend_b_title == "2030") {
  #     #   bubble_legend <- paste(folder, 'tables_maps/bubble_legend_2030_plain.PNG',sep='')
  #     # } else if  (legend_b_title == "2040") {
  #     #   bubble_legend <- paste(folder, 'tables_maps/bubble_legend_2040_plain.PNG',sep='')
  #     # } else if  (legend_b_title == "Exempt") { 
  #     #   bubble_legend <- paste(folder, 'tables_maps/bubble_legend_exempt_plain.PNG',sep='')
  #     # }
  #     # 
  #     # bubble_legend <- draw_image(bubble_legend,height = .72, x = 0.42, y = 0.05) #USE TO PLACE LEGEND TO THE RIGHT OF MAP
  #     
  #     
  #     map <- ggdraw(source_current +
  #                     geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.7) +
  #                     # ggtitle(paste("Well & Intake Source Locations - ",legend_b_title," Demand",sep="")) +
  #                     ggtitle(paste("Well & Intake Source Locations",sep="")) +
  #                     labs(subtitle = mb_name$name) +
  #                     #ADD GREY MB BACKGROUND
  #                     geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = "gray55",lwd=0.7) +
  #                     #ADD STATE BORDER LAYER ON TOP
  #                     geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
  #                     #ADD RIVERS LAYER ON TOP
  #                     geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
  #                     
  #                     #ADD BORDER 
  #                     geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  #                     
  #                     #ADD RIVER POINTS
  #                     #geom_point(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1),size =1, shape = 20, fill = "black")+
  #                     #ADD RIVER LABELS
  #                     geom_text_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 2, color = "dodgerblue3")+
  #                     #geom_label_repel(data = riv.centroid.df, aes(x = as.numeric(centroid_longitude), y = as.numeric(centroid_latitude), group = 1, label = GNIS_NAME),size = 1.75, color = "dodgerblue3", fill = NA, xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
  #                     
  #                     #ADD FIPS POINTS
  #                     geom_point(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1),
  #                                size =1, shape = 20, fill = "black")+
  #                     #ADD FIPS LABELS
  #                     geom_text_repel(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),
  #                                     size = 2)+
  #                     #geom_label_repel(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),size = 1.75, color = "black", fill = "white", xlim = c(-Inf, Inf), ylim = c(-Inf, Inf))+
  #                     
  #                    #ADD WITHDRAWAL LOCATIONS ON TOP (ALL MPS) #corrected_longitude, corrected_latitude
  #                     #---------------------------------------------------------------
  #                     geom_point(data = well_layer, aes(x = Longitude, y = Latitude), colour="black", fill ="green4", pch = 24, size = 2, alpha = 0.8) +
  #                     geom_point(data = intake_layer, aes(x = Longitude, y = Latitude), colour="black", fill ="purple4", pch = 21, size = 2, alpha = 0.8) +
  #                     #---------------------------------------------------------------
  #                   
  #                     #ADD NORTH BAR
  #                     north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  #                     base_scale +
  #                     base_theme+
  #                     theme(legend.position=c(1.137, .4))) +
  #       SourceTypeLegend + 
  #       deqlogo
  #   } #CLOSE rsegs IF STATEMENT
  #   
  # } #CLOSE WITHDRAWAL POINTS IF STATEMENT
  
  print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
  # ggsave(plot = map, file = export_file, width=5.5, height=5)
  ggsave(plot = map, file = export_file, width=6.5, height=5)

  
  
 # }
