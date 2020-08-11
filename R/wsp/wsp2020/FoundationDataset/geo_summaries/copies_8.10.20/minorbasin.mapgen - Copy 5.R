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


minorbasin.mapgen <- function(minorbasin,metric,runid_a,runid_b,mp_points = FALSE){
  
  #PRINT INPUTS RECIEVED - FOR DEBUGGING ONLY
  # print(minorbasin)
  # print(metric)
  # print(runid_a)
  # print(runid_b)
  
  #selects minor basin name
  mb_name <-sqldf(paste('SELECT name
              FROM "MinorBasins.csv" 
              WHERE code == "',minorbasin,'"',sep=""))
  
  print(paste("PROCESSING: ",mb_name,sep=""))
  
  #selects plot title based on chosen metric
  metric_title <- case_when(metric == "l30_Qout" ~ "30 Day Low Flow",
                            metric == "l90_Qout" ~ "90 Day Low Flow",
                            metric == "7q10" ~ "7Q10")
  #selects plot title based on chosen scenarios
  scenario_a_title <- case_when(runid_a == "runid_11" ~ "2020",
                                runid_a == "runid_12" ~ "2030",
                                runid_a == "runid_13" ~ "2040")
  scenario_b_title <- case_when(runid_b == "runid_12" ~ "2030",
                                runid_b == "runid_13" ~ "2040",
                                runid_b == "runid_14" ~ "p50 Climate Change",
                                runid_b == "runid_15" ~ "p10 Climate Change",
                                runid_b == "runid_16" ~ "p90 Climate Change",
                                runid_b == "runid_17" ~ "p10 Climate Change",
                                runid_b == "runid_18" ~ "Exempt Users",
                                runid_b == "runid_19" ~ "p50 Climate Change",
                                runid_b == "runid_20" ~ "p90 Climate Change")
  
  RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
  
  #figure out what MBs are tidal
  # sqldf("SELECT substr(hydrocode,1,18) AS basin
  #       from RSeg_summary
  #       WHERE hydrocode like '%_0000'
  #       GROUP BY basin
  #       ORDER BY basin")
  ######################################################################################################
  ######################################################################################################
  # DETERMINE MAP EXTENT FROM MINOR BASIN CENTROID

  if (minorbasin %in% c('TU')) {
    
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.7
    xmax <- mb.centroid$lng + 1.1
    ymin <- mb.centroid$lat - 1.4
    ymax <- mb.centroid$lat + 1.4
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))
    
  } else if (minorbasin %in% c('MN','OR')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.5
    xmax <- mb.centroid$lng + 1.7
    ymin <- mb.centroid$lat - 1.6
    ymax <- mb.centroid$lat + 1.6
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))
  
  } else if (minorbasin %in% c('JL')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.15
    xmax <- mb.centroid$lng + 1.25
    ymin <- mb.centroid$lat - 1.2
    ymax <- mb.centroid$lat + 1.2
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('PU')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.4
    xmax <- mb.centroid$lng + 1.4
    ymin <- mb.centroid$lat - 1.4
    ymax <- mb.centroid$lat + 1.4
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('EL','ES')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.2
    xmax <- mb.centroid$lng + 1.2
    ymin <- mb.centroid$lat - 1.35
    ymax <- mb.centroid$lat + 1.05
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('PS')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 0.9
    xmax <- mb.centroid$lng + 1.1
    ymin <- mb.centroid$lat - 1
    ymax <- mb.centroid$lat + 1
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
    
  } else {
    
    mb.row <- paste('SELECT *
              FROM "MinorBasins.csv" 
              WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1
    xmax <- mb.centroid$lng + 1
    ymin <- mb.centroid$lat - 1
    ymax <- mb.centroid$lat + 1
    
    extent <- data.frame(x = c(xmin, xmax),
                         y = c(ymin, ymax))

  }

  ######################################################################################################
  
  #bounding box
  bb=readWKT(paste0("POLYGON((",extent$x[1]," ",extent$y[1],",",extent$x[2]," ",extent$y[1],",",extent$x[2]," ",extent$y[2],",",extent$x[1]," ",extent$y[2],",",extent$x[1]," ",extent$y[1],"))",sep=""))
  bbProjected <- SpatialPolygonsDataFrame(bb,data.frame("id"), match.ID = FALSE)
  bbProjected@data$id <- rownames(bbProjected@data)
  bbPoints <- fortify(bbProjected, region = "id")
  bbDF <- merge(bbPoints, bbProjected@data, by = "id")
  

  ######################################################################################################
  ### PROCESS STATES LAYER  ############################################################################
  ######################################################################################################
  
  # #Need to remove Indiana due to faulty geom
  rm.IN <- paste('SELECT *
                FROM STATES
                WHERE state != "IN"
                ',sep="")
  STATES <- sqldf(rm.IN)
  
  STATES$id <- as.numeric(rownames(STATES))
  state.list <- list()
  
  #i <- 1
  for (i in 1:length(STATES$state)) {
    # print(paste("i = ",i,sep=''))
    # print(as.character(STATES$state[i]))
    state_geom <- readWKT(STATES$geom[i])
    #print(state_geom)
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
  st_data <- MinorBasins.csv
  
  MB_df_sql <- paste('SELECT *
              FROM st_data 
              WHERE code = "',minorbasin,'"'
                     ,sep="")
  st_data <- sqldf(MB_df_sql)
  
  st_data$id <- as.character(row_number(st_data$code))
  MB.list <- list()
  
  
  for (z in 1:length(st_data$code)) {
    # print(paste("z = ",z,sep=''))
    # print(st_data$code[z])
    MB_geom <- readWKT(st_data$geom[z])
    # print(MB_geom)
    MB_geom_clip <- gIntersection(bb, MB_geom)
    MBProjected <- SpatialPolygonsDataFrame(MB_geom_clip, data.frame('id'), match.ID = TRUE)
    MBProjected@data$id <- as.character(z)
    MB.list[[z]] <- MBProjected
  }
  MB <- do.call('rbind', MB.list)
  MB@data <- merge(MB@data, st_data, by = 'id')
  MB@data <- MB@data[,-c(2:3)]
  MB.df <- fortify(MB, region = 'id')
  MB.df <- merge(MB.df, MB@data, by = 'id')
  
  ######################################################################################################
  ### PROCESS Rivers
  # #####################################################################################################
  #summary(river_shp)
  #plot(river_shp)
  # proj4string(bbProjected) <- CRS("+proj=longlat +datum=WGS84")
  # bbProjected <- spTransform(bbProjected, CRS("+proj=longlat +datum=WGS84"))
  # river_shpProjected <- spTransform(river_shp, CRS("+proj=longlat +datum=WGS84"))
  # river_clip <- gIntersection(bbProjected,river_shpProjected)
  # river.df <- sp::SpatialLinesDataFrame(river_clip, data.frame('id'), match.ID = TRUE)

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
  length(RSeg_data[,1])

  # NEED TO REMOVE SECOND "hydrocode" COLUMN TO PREVENT ERROR LATER ON
  RSeg_data <- RSeg_data[,-which(colnames(RSeg_data)=="hydrocode" )[2]]
  
  # REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
  RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
  RSeg_data <- sqldf(RSeg_valid_geoms)
  length(RSeg_data[,1])
  
  # #use this to save rseg data
  # rsegdata <- sqldf("SELECT hydroid,name,hydrocode,featureid,runid_11,runid_12,runid_13,runid_14,runid_15,runid_16,runid_17,runid_18,runid_19,runid_20,pct_chg
  #       FROM RSeg_data
  #       order by pct_chg desc")
  # write.csv(rsegdata, file = paste0(folder, "tables_maps/",mb_name$name,"/",runid_a,"_to_",runid_b,"_",metric,"_",minorbasin,"_RSeg_data.csv",sep = ""))
  
  # ## # use this to investigate rseg data and see which rsegs might not have evaluated correctly or have NA/NULL values
  # missing_data <- sqldf("SELECT hydroid,name,hydrocode,featureid,runid_11,runid_12,runid_13,runid_14,runid_15,runid_16,runid_17,runid_18,runid_19,runid_20,pct_chg
  #       FROM RSeg_data
  #       WHERE pct_chg IS NULL")
  # write.csv(missing_data, file = paste0(folder, "tables_maps/",mb_name$name,"/",runid_a,"_to_",runid_b,"_",metric,"_",minorbasin,"_missing_RSeg_data.csv",sep = ""))
  ######################################################################################################
  ### GENERATE MAPS  ###############################################################################
  ######################################################################################################
  #SET UP BASE MAP
  base_map  <- ggplot(data = state.df, aes(x = long, y = lat, group = group))+
    geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
    # geom_polygon(data = bbDF, color="black", fill = NA,lwd=0.5)+
    geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5) +
    geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)
  
  # base_river <- geom_line(data = river.df,aes(x=long,y=lat, group=group), inherit.aes = FALSE,  show.legend=FALSE, color = 'royalblue4', size = .5)
  
  # base_scale <-  ggsn::scalebar(data = bbDF, location = 'bottomright', dist = 25, dist_unit = 'mi', 
  #                               transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
  #                               st.size = 3, st.dist = 0.03,
  #                               anchor = c(
  #                                 # x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])+1.1,
  #                                 x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])+1.0,
  #                                 y = extent$y[1]+(extent$y[1])*0.001
  #                               ))
  
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
  
  #select correct image path for the right legend (regular or with tidal segment)
  if (minorbasin %in% c('JA','PL','RL','YL','YM','YP','EL','JB','MN','ES')) {
    
    image_path <- paste(folder, 'tables_maps/legend_rseg_tidal_segment.PNG',sep='')
    
  } else {
    image_path <- paste(folder, 'tables_maps/legend_rseg.PNG',sep='')
  }
  #select the legend position based on how much marginal space each minorbasin has around it
  if (minorbasin %in% c('RL','YM','YP','JB','YL','OR','PL','MN')) {
    base_legend <- draw_image(image_path,height = .26, x = -.355, y = .05)
  } else  {
    base_legend <- draw_image(image_path,height = .26, x = -.355, y = .6 )
  }  
  ######################################################################################################
  #colnames(RSeg_data)
  group_0_plus <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg >= 0")  
  group_0_plus <- sqldf(group_0_plus)
  group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')
  
  color_values <- list()
  label_values <- list()
  
  if (nrow(group_0_plus) >0) {
    
    geom1 <- geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)
    
    color_values <- "darkolivegreen3"
    
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
    color_values <- rbind(color_values,"cornflowerblue")
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
    color_values <- rbind(color_values,"khaki2")
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
    color_values <- rbind(color_values,"plum3")
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
    color_values <- rbind(color_values,"coral3")
    label_values <- rbind(label_values,"More than -20%")
    
  } else  {
    
    geom5 <- geom_blank()
    
  }
  
  #---------------------------------------------------------------
  
  #create a geom_sf for the tidal segments that are plotted a default color
  if (
    any(nrow(group_0_plus) == 0,nrow(group_neg5_0) == 0,nrow(group_neg10_neg5) == 0,nrow(group_neg20_neg10) == 0,nrow(group_negInf_neg20) == 0) == TRUE) {
    group_tidal <- st_as_sf(RSeg_data, wkt = 'geom')
    geom_tidal <- geom_sf(data = group_tidal,aes(geometry = geom,fill = 'gray04'), inherit.aes = FALSE)
    color_values <- rbind(color_values,"gray40")
    label_values <- rbind(label_values,"Tidal Segment")

  }  else  {
    
    if(exists(x = 'group_tidal')){rm(group_tidal)}
    geom_tidal <- geom_blank()
    
  } 
  
  #print(geom_tidal)
  
  ####################################################################
  source_current <- base_map +
    geom_tidal +
    geom1 +
    geom2 +
    geom3 +
    geom4 +
    geom5 +
    scale_fill_manual(values=color_values,
                      name = "Legend",
                      labels = label_values)+
    
    guides(fill = guide_legend(reverse=TRUE))
  
  # print(geom5)
  # 
  # 
  #  ES.MB.df <<- MB.df
  # length(ES.MB.df$geom)
   
  map <- ggdraw(source_current +
  #map <- ggdraw(base_map +
                  #geom_tidal +
                  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.7) +
                  ggtitle(paste(metric_title," (Percent Change ",scenario_a_title," to ",scenario_b_title,")",sep = '')) +
                  labs(subtitle = mb_name$name) +
                  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
                  # base_river +
                  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                  
                  # ADD BORDER ####################################################################
                  geom_polygon(data = bbDF, color="black", fill = NA,lwd=0.5)+
                  
                  base_scale +
                  base_theme) +
    base_legend
  
  
  export_file <- paste0(export_path, "tables_maps/Xfigures/",minorbasin,"_",runid_a,"_to_",runid_b,"_",metric,"_map.png",sep = "")
  print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
  
  ggsave(plot = map, file = export_file, width=6.5, height=5)
  
  
}