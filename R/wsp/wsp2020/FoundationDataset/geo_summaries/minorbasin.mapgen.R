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

minorbasin.mapgen <- function(minorbasin,metric,runid_a,runid_b){
  
  # SELECT MINOR BASIN NAME
  mb_name <-sqldf(paste('SELECT name
              FROM "MinorBasins.csv" 
              WHERE code == "',minorbasin,'"',sep=""))
  print(paste("PROCESSING: ",mb_name,sep=""))
  
  # RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
  RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
  

  ######################################################################################################
  # DETERMINE MAP EXTENT FROM MINOR BASIN CENTROID
  extent <- mb.extent(minorbasin,MinorBasins.csv)
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
  ### PROCESS Minor Basin LAYER  #######################################################################
  ######################################################################################################
  mb_data <- MinorBasins.csv
  
  MB_df_sql <- paste('SELECT *
              FROM mb_data 
              WHERE code = "',minorbasin,'"'
                     ,sep="")
  mb_data <- sqldf(MB_df_sql)
  
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
  ### PROCESS FIPS LAYER  #############################################################################
  ######################################################################################################

  # #PADDING TO ENSURE FIPS NAMES DONT GO BEYOND PLOT WINDOW
  # fips_extent <- data.frame(x = c(extent$x[1]+0.25, extent$x[2]-0.25),
  #                           y = c(extent$y[1]+0.25, extent$y[2]-0.25))
  # fips_bb=readWKT(paste0("POLYGON((",fips_extent$x[1]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[1],"))",sep=""))
  
  fips_layer <- fips.csv
  fips_layer$id <- fips_layer$fips_hydroid
  fips.list <- list()

  for (f in 1:length(fips_layer$fips_hydroid)) {
    fips_geom <- readWKT(fips_layer$fips_centroid[f])
    fips_geom_clip <- gIntersection(MB_geom, fips_geom) #SHOW ONLY FIPS NAMES WITHIN MINOR BASIN
   
    if (is.null(fips_geom_clip) == TRUE) {
        # print("FIPS OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    fipsProjected <- SpatialPointsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    fipsProjected@data$id <- as.character(fips_layer[f,]$id)
    fips.list[[f]] <- fipsProjected
  }
  
  length(fips.list)
  #REMOVE THOSE FIPS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  fips.list <- fips.list[which(!sapply(fips.list, is.null))]
  length(fips.list)
  
  if (length(fips.list) != 0) {
  #  print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT - SKIPPING")
    fips <- do.call('rbind', fips.list)
    fips@data <- merge(fips@data, fips_layer, by = 'id')
    fips@data <- fips@data[,-c(2:3)]
    fips.df <- data.frame(fips)
  } else {
    print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT")
  
    fips.df <- data.frame(id=c(1,2),
                          fips_latitude =c(1,2), 
                          fips_longitude =c(1,2),
                          fips_name = c(1,2),
                          stringsAsFactors=FALSE) 
  
   }

  
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
  
  rivs_layer$id <- rivs_layer$feature
  rivs.list <- list()
  
  #r <- 2
  for (r in 1:length(rivs_layer$feature)) {
    riv_geom <- readWKT(rivs_layer$geom[r])
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

  ######################################################################################################
  ### PROCESS RSegs
  ######################################################################################################
  # JOIN DATA BY RIVER SEGMENT TO RIVER SEGMENT GEOMETRY LAYER
  RSeg_data <- paste('SELECT *,
                  case
                  when b.',runid_a,' = 0
                  then 0
                  when b.',runid_b,' IS NULL
                  then NULL
                  else round(((b.',runid_b,' - b.',runid_a,') / b.',runid_a,') * 100,2)
                  end AS pct_chg
                  FROM "RSeg.csv" AS a
                  LEFT OUTER JOIN RSeg_summary AS b
                  ON (a.hydrocode = b.hydrocode)
                  WHERE a.hydrocode LIKE "%wshed_',minorbasin,'%"',sep = '')  
  
  
  RSeg_data <- sqldf(RSeg_data)
  #print(length(RSeg_data[,1]))

  # NEED TO REMOVE SECOND "hydrocode" COLUMN TO PREVENT ERROR LATER ON
  RSeg_data <- RSeg_data[,-which(colnames(RSeg_data)=="hydrocode" )[2]]
  
  # REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
  RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
  RSeg_data <- sqldf(RSeg_valid_geoms)
  #print(length(RSeg_data[,1]))
  
  #PL_hcodes <<- RSeg_data[,1:5]
  
  
  # USE THIS TO REMOVE ANY "_0000" TIDAL SEGMENTS - THEY WILL APPEAD AR GAPS ON THE MAP
  # RSeg_non_tidal <- paste("SELECT *
  #                 FROM RSeg_data
  #                 WHERE hydrocode NOT LIKE '%_0000'")
  # RSeg_data <- sqldf(RSeg_non_tidal)
  # print(length(RSeg_data[,1]))

  ######################################################################################################
  ### PLOTTING TITLES  #################################################################################
  ######################################################################################################
  # SELECT PLOT TITLE BASED ON CHOSEN METRIC
  metric_title <- case_when(metric == "l30_Qout" ~ "30 Day Low Flow",
                            metric == "l90_Qout" ~ "90 Day Low Flow",
                            metric == "7q10" ~ "7Q10",
                            metric == "l30_cc_Qout" ~ "30 Day Low Flow",
                            metric == "l90_cc_Qout" ~ "90 Day Low Flow",)
  
  # SELECT PLOT TITLE BASED ON CHOSE SCENARIOS
  scenario_a_title <- case_when(runid_a == "runid_11" ~ "2020",
                                runid_a == "runid_12" ~ "2030",
                                runid_a == "runid_13" ~ "2040")
  scenario_b_title <- case_when(runid_b == "runid_12" ~ "2030",
                                runid_b == "runid_13" ~ "2040",
                                runid_b == "runid_14" ~ "Med Climate Change",
                                runid_b == "runid_15" ~ "Dry Climate Change",
                                runid_b == "runid_16" ~ "Wet Climate Change",
                                runid_b == "runid_17" ~ "Dry Climate Change",
                                runid_b == "runid_18" ~ "Exempt Users",
                                runid_b == "runid_19" ~ "Med Climate Change",
                                runid_b == "runid_20" ~ "Wet Climate Change")
  
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
  
  base_scale <-  ggsn::scalebar(data = bbDF, location = 'bottomleft', dist = 25, dist_unit = 'mi', 
                                transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
                                st.size = 3, st.dist = 0.03,
                                 anchor = c(
                                   x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-0.45,
                                   y = extent$y[1]+(extent$y[1])*0.001
                                 ))
  
  base_theme <- theme(legend.justification=c(0,1), 
                      legend.position="none",
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
   color_scale <- c("white","navajowhite","sandybrown","#ad6c51","#754b39","gray55")
   
  #SELECT LEGEND IMAGE PATH (WITH OR WITHOUT TIDAL SEGMENT)
  if (minorbasin %in% c('JA','PL','RL','YL','YM','YP','EL','JB','MN','ES')) {
     image_path <- paste(folder, 'tables_maps/legend_rseg_tidal_segment.PNG',sep='')
  } else {
     image_path <- paste(folder, 'tables_maps/legend_rseg.PNG',sep='')
  }
  
  base_legend <- draw_image(image_path,height = .26, x = -.41, y = .6)
  
  #logo bottom left placement outside map extent
  # deqlogo <- draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1,  x = -.42, y = -.42)
  #logo lop left placement inside map extent
  deqlogo <- draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1,  x = -.235, y = 0.33)
  

  ######################################################################################################
  group_0_plus <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg >= 0")  
  group_0_plus <- sqldf(group_0_plus)
  group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')
  
  color_values <- list()
  label_values <- list()
  
  if (nrow(group_0_plus) >0) {
    
    geom1 <- geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)
    
    color_values <- color_scale[1]
    
    label_values <- ">= 0%"
    
  } else  {
    
    geom1 <- geom_blank()
    
  }
  #-----------------------------------------------------------------------------------------------------
  group_neg5_0 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < 0 AND pct_chg >= -5")  
  group_neg5_0 <- sqldf(group_neg5_0)
  group_neg5_0 <- st_as_sf(group_neg5_0, wkt = 'geom')
  
  if (nrow(group_neg5_0) >0) {
    
    geom2 <- geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'antiquewhite1'), inherit.aes = FALSE)
    color_values <- rbind(color_values,color_scale[2])
    label_values <- rbind(label_values,"-5% to 0%")
    
  } else  {
    
    geom2 <- geom_blank()
    
  }
  #-----------------------------------------------------------------------------------------------------
  group_neg10_neg5 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < -5 AND pct_chg >= -10")  
  group_neg10_neg5 <- sqldf(group_neg10_neg5)
  group_neg10_neg5 <- st_as_sf(group_neg10_neg5, wkt = 'geom')
  
  if (nrow(group_neg10_neg5) >0) {
    
    geom3 <- geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'antiquewhite2'), inherit.aes = FALSE)
    color_values <- rbind(color_values,color_scale[3])
    label_values <- rbind(label_values,"-10% to -5%")
    
  } else  {
    
    geom3 <- geom_blank()
    
  }
  
  #-----------------------------------------------------------------------------------------------------
  group_neg20_neg10 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < -10 AND pct_chg >= -20")  
  group_neg20_neg10 <- sqldf(group_neg20_neg10)
  group_neg20_neg10 <- st_as_sf(group_neg20_neg10, wkt = 'geom')
  
  if (nrow(group_neg20_neg10) >0) {
    
    geom4 <- geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'antiquewhite3'), inherit.aes = FALSE)
    color_values <- rbind(color_values,color_scale[4])
    label_values <- rbind(label_values,"-20% to -10%")
    
  } else  {
    
    geom4 <- geom_blank()
    
  }
  #-----------------------------------------------------------------------------------------------------
  group_negInf_neg20 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg <= -20")  
  group_negInf_neg20 <- sqldf(group_negInf_neg20)
  group_negInf_neg20 <- st_as_sf(group_negInf_neg20, wkt = 'geom')
  
  if (nrow(group_negInf_neg20) >0) {
    
    geom5 <- geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'antiquewhite4'), inherit.aes = FALSE)
    color_values <- rbind(color_values,color_scale[5])
    label_values <- rbind(label_values,"More than -20%")
    
  } else  {
    
    geom5 <- geom_blank()
    
  }
  
  #---------------------------------------------------------------
  # DATAFRAME OF ANY "_0000" TIDAL SEGMENTS
  RSeg_tidal <- paste("SELECT *
                  FROM RSeg_data
                  WHERE hydrocode LIKE '%_0000'")
  RSeg_tidal <- sqldf(RSeg_tidal)

  if ((length(RSeg_tidal[,1]) >= 1) == TRUE) {

    group_tidal_base <- st_as_sf(RSeg_data, wkt = 'geom')
    geom_tidal_base <- geom_sf(data = group_tidal_base,aes(geometry = geom,fill = color_scale[6]), inherit.aes = FALSE)
    
    
    group_tidal <- st_as_sf(RSeg_tidal, wkt = 'geom')
    geom_tidal <- geom_sf(data = group_tidal,aes(geometry = geom,fill = color_scale[6]), inherit.aes = FALSE)
    color_values <- rbind(color_values,color_scale[6])
    label_values <- rbind(label_values,"Tidal Segment")

  } else  {

      if(exists(x = 'group_tidal')){rm(group_tidal)}
      geom_tidal_base <- geom_blank()
      geom_tidal <- geom_blank()

  }
  

  ####################################################################
  source_current <- base_map +
    geom_tidal_base +
    geom1 +
    geom2 +
    geom3 +
    geom4 +
    geom5 +
    scale_fill_manual(values=color_values,
                      name = "Legend",
                      labels = label_values)+
    guides(fill = guide_legend(reverse=TRUE))
  

  
  #ADD TIDAL RSEGS LAYER ON TOP FOR THOSE MINOR BASINS THAT HAVE TIDAL RSEGS
  # *note, if the following if statement was removed and geom_tidal layer still 
  #     added on top, the resulting maps will be 100% identical to the vahydro mapserv maps
  #     i.e. minor basins such as TU will have _0000 rsegs greyed out (but thats yucky)
  if (minorbasin %in% c('JA','PL','RL','YL','YM','YP','EL','JB','MN','ES')) {
    source_current <- source_current + geom_tidal
  }

  map <- ggdraw(source_current +
                  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.7) +
                  ggtitle(paste(metric_title," (Percent Change ",scenario_a_title," to ",scenario_b_title,")",sep = '')) +
                  labs(subtitle = mb_name$name) +
                  # north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                  
                  #ADD STATE BORDER LAYER ON TOP
                  geom_path(data = state.df,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5) +
                  
                  #ADD RIVERS LAYER ON TOP
                  geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
               
                  
                  # ADD BORDER ####################################################################
                  geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+

                  geom_point(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1),
                              size =1, shape = 20, fill = "black")+

                  geom_text_repel(data = fips.df, aes(x = fips_longitude, y = fips_latitude, group = 1, label = fips_name),
                              size = 2)+
    
                  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                  base_scale +
                  base_theme) +
                  base_legend +
                  deqlogo 

  export_file <- paste0(export_path, "tables_maps/Xfigures/",minorbasin,"_",runid_a,"_to_",runid_b,"_",metric,"_map.png",sep = "")
  print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
  
  ggsave(plot = map, file = export_file, width=6.5, height=5)
  
  
}