#base

library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma

######################################################################################################
### LOAD LAYERS  #####################################################################################
######################################################################################################
minorbasin <- "shenandoah"

#Metric options include "7q10", "l30_Qout", "l90_Qout"
metric <- "l30_Qout"

STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
RSeg.csv <- read.table(file = 'C:/Users/maf95834/Documents/Github/hydro-tools/GIS_LAYERS/VAHydro_RSegs.csv', sep = ',', header = TRUE)
river_shp <- readOGR("C:/Users/maf95834/Documents/Github/hydro-tools/GIS_LAYERS/MajorRivers", "MajorRivers")

#selects plot title based on chosen metric
plot_title <- case_when(metric == "l30_Qout" ~ "30 Day Low Flow",
                        metric == "l90_Qout" ~ "90 Day Low Flow",
                        metric == "7q10" ~ "7Q10")

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
# data_minorbasin_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
# county_shp <- readOGR("U:/OWS/GIS/VA_Counties", "VA_Counties")
######################################################################################################

#specify spatial extent for map  
#extent <- data.frame(x = c(-84, -75), 
#                     y = c(35, 41))  

extent <- data.frame(x = c(-77.50, -79.55),
                     y = c(37.7, 39.5))

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
#   rm.IN <- paste('SELECT *
#                 FROM STATES 
#                 WHERE state != "IN"
#                 ',sep="")
#   STATES <- sqldf(rm.IN)

#Need to remove Indiana due to faulty geom
rm.IN <- paste('SELECT *
              FROM STATES 
              WHERE state IN ("MD","VA","WV") 
              ',sep="")
STATES <- sqldf(rm.IN)

STATES$id <- as.numeric(rownames(STATES))
state.list <- list()

#i <- 1
for (i in 1:length(STATES$state)) {
  print(paste("i = ",i,sep=''))
  print(as.character(STATES$state[i]))
  state_geom <- readWKT(STATES$geom[i])
  #print(state_geom)
  state_geom_clip <- gIntersection(bb, state_geom)
  stateProjected <- SpatialPolygonsDataFrame(state_geom_clip, data.frame('id'), match.ID = TRUE)
  stateProjected@data$id <- as.character(i)
  state.list[[i]] <- stateProjected
}
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
              WHERE code = "PS" 
              ',sep="")
st_data <- sqldf(MB_df_sql)


st_data$id <- as.character(row_number(st_data$code))
MB.list <- list()

for (z in 1:length(st_data$code)) {
  print(paste("z = ",z,sep=''))
  print(st_data$code[z])
  MB_geom <- readWKT(st_data$geom[z])
  #print(MB_geom)
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
#summary(river_shp)
#plot(river_shp)
proj4string(MBProjected) <- CRS("+proj=longlat +datum=WGS84")
MBProjected <- spTransform(MBProjected, CRS("+proj=longlat +datum=WGS84"))
river_shpProjected <- spTransform(river_shp, CRS("+proj=longlat +datum=WGS84"))
river_clip <- gIntersection(MBProjected,river_shpProjected)
river.df <- sp::SpatialLinesDataFrame(river_clip, data.frame('id'), match.ID = TRUE)
#summary(river.df)
plot(river.df)######################################################################################################
# #SUBSET COUNTIES
# #manual selection of counties
# 
# mb_points <- sqldf("SELECT *
#                    FROM data_minorbasin_raw
#                    WHERE MinorBasin_Code = 'PS'")
# 
# ###Good QA Method to see if any MPs might have the wrong fips - this would skew the by county kable tables
# # # #view what fips actually have MPs in them (helps with manual county selection)
# # x <- sqldf("SELECT distinct fips_code, fips_name from mb_points")
# # x$fips_code
# # shen_counties2 <- subset(county_shp, FIPS %in% x$fips_code)
# # plot(shen_counties2)
# 
# county_subset <- subset(county_shp, FIPS %in% c(51187,
#                                                 51165, 
#                                                 51820,
#                                                 51015,
#                                                 51171,
#                                                 51069,
#                                                 51139,
#                                                 51043,   
#                                                 51660))
# county_projected <- spTransform(county_subset, CRS("+proj=longlat +datum=WGS84"))
# county_projected@data$id = rownames(county_projected@data)
# county_projected.points = fortify(county_projected, region="id")
# county_points.df = inner_join(county_projected.points, county_projected@data, by="id")
# 
# #select by subsetting with the minor basin boundary
# proj4string(MBProjected) <- CRS("+proj=longlat +datum=WGS84")
# MBProjected <- spTransform(MBProjected, CRS("+proj=longlat +datum=WGS84"))
# county_projected <- spTransform(county_shp, CRS("+proj=longlat +datum=WGS84"))
# county_MB <- county_projected[MBProjected, ]
# county_MB@data$id = rownames(county_MB@data)
# county_MB.points = fortify(county_MB, region="id")
# county_MB.df = inner_join(county_MB.points, county_MB@data, by="id")
# names(county_MB.df)
# 
# # #select by subsetting with the bounding box extent 
# # #seems to dissolve the lines inside
# # plot(bbProjected)
# # proj4string(bbProjected) <- CRS("+proj=longlat +datum=WGS84")
# # bbProjected <- spTransform(bbProjected, CRS("+proj=longlat +datum=WGS84"))
# # county_projected <- spTransform(county_shp, CRS("+proj=longlat +datum=WGS84"))
# # county_clip <- gIntersection(bbProjected,county_projected)
# # county_bb.df <- sp::SpatialPolygonsDataFrame(county_clip, data.frame('id'), match.ID = TRUE)
# # plot(county_clip)
# # 
# # #select counties that intersect the bb extent boundary line which makes it plot outside the lines 
# # plot(bbProjected)
# # proj4string(bbProjected) <- CRS("+proj=longlat +datum=WGS84")
# # bbProjected <- spTransform(bbProjected, CRS("+proj=longlat +datum=WGS84"))
# # county_projected <- spTransform(county_shp, CRS("+proj=longlat +datum=WGS84"))
# # county_bb <- county_projected[bbProjected, ]
# # county_bb@data$id = rownames(county_bb@data)
# # county_bb.points = fortify(county_bb, region="id")
# # county_bb.df = inner_join(county_bb.points, county_bb@data, by="id")
# # names(county_bb.df)
# # plot(county_bb)

######################################################################################################
### PROCESS RSegs
######################################################################################################
# JOIN DATA BY RIVER SEGMENT TO RIVER SEGMENT GEOMETRY LAYER
RSeg_data <- paste("SELECT *,
                  round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_13,
                  round(((b.runid_15 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_15,
                  round(((b.runid_16 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_16,
                  round(((b.runid_18 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_18
                  FROM 'RSeg.csv' AS a
                  LEFT OUTER JOIN RSeg_summary AS b
                  ON (a.hydrocode = b.hydrocode)
                  WHERE a.hydrocode LIKE '%PS%'")  
RSeg_data <- sqldf(RSeg_data)
length(RSeg_data[,1])

# REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
RSeg_data <- sqldf(RSeg_valid_geoms)
length(RSeg_data[,1])

######################################################################################################
### GENERATE MAPS  ###############################################################################
######################################################################################################
#SET UP BASE MAP
base_map  <- ggplot(data = state.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5) 

base_river <- geom_line(data = river.df,aes(x=long,y=lat, group=group), inherit.aes = FALSE,  show.legend=FALSE, color = 'royalblue4', size = .5)

base_scale <-  ggsn::scalebar(data = bbDF, location = 'bottomright', dist = 25, dist_unit = 'mi', 
                              transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
                              st.size = 3, st.dist = 0.03,
                              anchor = c(
                                x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])+0.9,
                                y = extent$y[1]+(extent$y[1])*0.001
                              ))
  
base_theme <- theme(legend.justification=c(0,1), 
                    legend.position=c(0,1),
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
###################################################################################
#CURRENT 2020 to 2040 - 11 to 13 
source("C:/Users/maf95834/Documents/Github/vahydro/R/wsp/wsp2020/FoundationDataset/geo_summaries/single_basin_model_maps/current_11_to_13.R")

current_map <- source_current +
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5) +
  ggtitle(paste(plot_title," (Percent Change 2020 to 2040)",sep = '')) +
  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  base_river +
  base_scale +
  base_theme #+
  #geom_polygon(data = county_points.df, aes(x = long, y = lat, fill = Name), alpha = .5,inherit.aes = FALSE,  show.legend=FALSE) +
  #geom_polygon(data = county_border.df, aes(x = long, y = lat, group = group),color = 'gray40',fill = 'cornflowerblue', alpha = .1,inherit.aes = FALSE,  show.legend=FALSE) +
  #geom_polygon(data = county_bb.df, aes(x = long, y = lat, group = group),color = 'gray40',fill = 'cornflowerblue', alpha = .1,inherit.aes = FALSE,  show.legend=FALSE)

ggsave(plot = current_map, file = paste0(folder, "state_plan_figures/single_basin/chg_11_to_13_",metric,"_",minorbasin,"_map.png"), width=6.5, height=5)

#---------------------------------------------------------------#

#CURRENT 2020 to p10 - 11 to 15 
source("C:/Users/maf95834/Documents/Github/vahydro/R/wsp/wsp2020/FoundationDataset/geo_summaries/single_basin_model_maps/p10_11_to_15.R")

p10_map <- source_p10 +
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  ggtitle(paste(plot_title," (Percent Change 2020 to p10 Climate Change)",sep = '')) +
  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  base_river +
  base_scale +
  base_theme

ggsave(plot = p10_map, file = paste0(folder, "state_plan_figures/single_basin/chg_11_to_15_",metric,"_",minorbasin,"_map.png"), width=6.5, height=5)

#---------------------------------------------------------------#

#CURRENT 2020 to p90 - 11 to 16 
source("C:/Users/maf95834/Documents/Github/vahydro/R/wsp/wsp2020/FoundationDataset/geo_summaries/single_basin_model_maps/p90_11_to_16.R")

p90_map <- source_p90 +
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  ggtitle(paste(plot_title," (Percent Change 2020 to p90 Climate Change)",sep = '')) +
  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  base_river +
  base_scale +
  base_theme

ggsave(plot = p90_map, file = paste0(folder, "state_plan_figures/single_basin/chg_11_to_16_",metric,"_",minorbasin,"_map.png"), width=6.5, height=5)

#---------------------------------------------------------------#

#CURRENT 2020 to Exempt Users - 11 to 18 
source("C:/Users/maf95834/Documents/Github/vahydro/R/wsp/wsp2020/FoundationDataset/geo_summaries/single_basin_model_maps/exempt_11_to_18.R")


exempt_map <- source_exempt +
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
  ggtitle(paste(plot_title," (Percent Change 2020 to Exempt Users Run)",sep = '')) +
  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  base_river +
  base_scale +
  base_theme

ggsave(plot = exempt_map, file = paste0(folder, "state_plan_figures/single_basin/chg_11_to_18_",metric,"_",minorbasin,"_map.png"), width=6.5, height=5)
