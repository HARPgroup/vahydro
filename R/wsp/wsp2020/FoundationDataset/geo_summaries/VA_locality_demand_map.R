# STATEWIDE VA DEMAND BY LOCALITY MAPS

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
export_file <- paste0(folder, "tables_maps/Xfigures/VA_locality_demand_map.png")

#DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
localpath <- tempdir()
MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)

#DOWNLOAD FIPS GEOM LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_geom_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips_geom.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD RAW mp.all FILE
mp.all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#LOAD MAPPING FUNCTIONS
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

#DEMAND TABLE 
va_demand <- read.csv(paste0(folder, "tables_maps/Xtables/VA_locality_demand.csv"))

############################################################################################
# VA MAP - PERCENT CHANGE ##################################################################
############################################################################################

# #CUSTOM DIVS *NOTE* Currently the legend is not dynamic, but a static image
#good divs for consumptive_use_frac
div1 <- -50
div2 <- -25
div3 <- 0
div4 <- 25
div5 <- 50
div6 <- 100

color_scale <- c("#ad6c51","#d98f50","#f7d679","#E4FFB9","darkolivegreen2","darkolivegreen3","darkolivegreen")

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
### PROCESS FIPS GEOM LAYER  #####################################################################
######################################################################################################

fips_data <- paste('SELECT *
                  FROM "fips_geom.csv" AS a
                  LEFT OUTER JOIN va_demand AS b
                  ON (a.fips_code = b.fips_code)
                  WHERE a.fips_code LIKE "51%"
                     AND a.fips_code NOT LIKE "51685"
                  ',sep = '')

fips_layer <- sqldf(fips_data)
fips_layer[is.na(fips_layer)] <- 0.00
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
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color= NA, fill = NA,lwd=0.5)

base_scale <- ggsn::scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'mi',
                             transform = TRUE, model = 'WGS84',st.bottom=FALSE,
                             st.size = 3.5, st.dist = 0.0285,
                             anchor = c(
                               x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-1.8,
                               y = extent$y[1]+(extent$y[1])*0.001
                             ))

base_theme <- theme(legend.justification=c(0,1), 
                    legend.position="none",
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

base_legend <- draw_image("U:/OWS/foundation_datasets/wsp/wsp2020/tables_maps/legend_locality_demand.png",height = .35, x = -.38, y = .515) #LEFT TOP LEGEND

deqlogo <- draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1, x = -.388, y = -0.402) #LEFT BOTTOM LOGO
######################################################################################################
#VA POP PCT CHANGE - BREAK INTO BINS

c_border <- 'gray30'

group_div1 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change <= ",div1)
group_div1 <- sqldf(group_div1)
group_div1 <- st_as_sf(group_div1, wkt = 'fips_geom')

color_values <- list()
label_values <- list()

if (nrow(group_div1) >0) {
  
  geom1 <- geom_sf(data = group_div1, fill = color_scale[1],color = c_border, inherit.aes = FALSE)
  
  color_values <- color_scale[1]
  
  label_values <- paste(" <= ",div1,sep="")
  
} else  {
  
  geom1 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div1_div2 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div1," AND pct_change <= ",div2)
group_div1_div2 <- sqldf(group_div1_div2)
group_div1_div2 <- st_as_sf(group_div1_div2, wkt = 'fips_geom')


if (nrow(group_div1_div2) >0) {
  
  geom2 <- geom_sf(data = group_div1_div2,fill = color_scale[2],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div1," to ",div2,sep=""))
  
} else  {
  
  geom2 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div2_div3 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div2," AND pct_change <= ",div3)
group_div2_div3 <- sqldf(group_div2_div3)
group_div2_div3 <- st_as_sf(group_div2_div3, wkt = 'fips_geom')


if (nrow(group_div2_div3) >0) {
  
  geom3 <- geom_sf(data = group_div2_div3, fill = color_scale[3],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[3])
  label_values <- rbind(label_values,paste(div2," to ",div3,sep=""))
  
} else  {
  
  geom3 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div3_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div3," AND pct_change <= ",div4)
group_div3_div4 <- sqldf(group_div3_div4)
group_div3_div4 <- st_as_sf(group_div3_div4, wkt = 'fips_geom')


if (nrow(group_div3_div4) >0) {
  
  geom4 <- geom_sf(data = group_div3_div4, fill = color_scale[4],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[4])
  label_values <- rbind(label_values,paste(div3," to ",div4,sep=""))
  
} else  {
  
  geom4 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div4_div5 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div4," AND pct_change <= ",div5)
group_div4_div5 <- sqldf(group_div4_div5)
group_div4_div5 <- st_as_sf(group_div4_div5, wkt = 'fips_geom')


if (nrow(group_div4_div5) >0) {
  
  geom5 <- geom_sf(data = group_div4_div5, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[5])
  label_values <- rbind(label_values,paste(div4," to ",div5,sep=""))
  
} else  {
  
  geom5 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div5_div6 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change > ",div5," AND pct_change <= ",div6)
group_div5_div6 <- sqldf(group_div5_div6)
group_div5_div6 <- st_as_sf(group_div5_div6, wkt = 'fips_geom')


if (nrow(group_div5_div6) >0) {
  
  geom6 <- geom_sf(data = group_div5_div6, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[6])
  label_values <- rbind(label_values,paste(div5," to ",div6,sep=""))
  
} else  {
  
  geom6 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div6 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE pct_change >= ",div6)
group_div6 <- sqldf(group_div6)
group_div6 <- st_as_sf(group_div6, wkt = 'fips_geom')


if (nrow(group_div6) >0) {
  
  geom7 <- geom_sf(data = group_div6, fill = color_scale[7],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[7])
  label_values <- rbind(label_values,paste(" >= ",div6,sep=""))
  
} else  {
  
  geom7 <- geom_blank()
  
}


####################################################################
source_current <- base_map +
  geom1 +
  geom2 +
  geom3 +
  geom4 +
  geom5 +
  geom6 +
  geom7 

#ggsave(plot = source_current, file =  paste0(folder, "JM_VA_locality_demand_map_TEST.png"), width=6.5, height=5) 

map <- ggdraw(source_current +
                ggtitle("Virginia Demand by Locality") +
                labs(subtitle = "2020 to 2040 Percent Change") +
                
                #ADD MINOR BASIN BORDER LAYER ON TOP
                #geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.65) +
                #ADD STATE BORDER LAYER ON TOP
                geom_path(data = state.df,aes(x = long, y = lat, group = group), color="black",lwd=0.4) +
                #ADD VIRGINIA STATE BORDER LAYER ON TOP
                geom_sf(data = va_state_sf, fill = NA,color = "black", lwd=0.75, inherit.aes = FALSE) +
                #ADD RIVERS LAYER ON TOP
                geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
                #ADD BORDER 
                geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
                #ADD NORTH BAR
                north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                base_scale +
                base_theme) +
  deqlogo +
  base_legend
#map

print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
# ggsave(plot = map, file = export_file, width=5.5, height=5)
ggsave(plot = map, file = export_file, width=6.5, height=5)
beep(sound = 1)




############################################################################################
# SURFACE WATER MAP - PERCENT CHANGE  ######################################################
############################################################################################



############################################################################################
# GROUNDWATER MAP - PERCENT CHANGE  ########################################################
############################################################################################












############################################################################################
# VA MAP - 2020 DEMAND #####################################################################
############################################################################################
export_file <- paste0(folder, "tables_maps/Xfigures/VA_2020_locality_demand_map.png")
#DEMAND TABLE 
va_demand <- read.csv(paste0(folder, "tables_maps/Xtables/VA_locality_demand.csv"))
# #CUSTOM DIVS *NOTE* Currently the legend is not dynamic, but a static image
#div1 <- 0
div1 <- 10
div2 <- 50
div3 <- 100
div4 <- 500
#div6 <- 1000

color_scale <- c("#d98f50","#f7d679","#E4FFB9","darkolivegreen2","darkolivegreen")
### PROCESS FIPS GEOM LAYER  #####################################################################
fips_data <- paste('SELECT *
                  FROM "fips_geom.csv" AS a
                  LEFT OUTER JOIN va_demand AS b
                  ON (a.fips_code = b.fips_code)
                  WHERE a.fips_code LIKE "51%"
                     AND a.fips_code NOT LIKE "51685"
                  ',sep = '')

fips_layer <- sqldf(fips_data)
fips_layer[is.na(fips_layer)] <- 0.00
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

#LEFT TOP LEGEND
base_legend <- draw_image("U:/OWS/foundation_datasets/wsp/wsp2020/tables_maps/legend_locality_demand_2020_5bins.png",height = .35, x = -.39, y = .517) 

### #VA LOCALITY 2020 DEMAND - BREAK INTO BINS ##########################################
c_border <- 'gray30'

group_div1 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 <= ",div1)
group_div1 <- sqldf(group_div1)
group_div1 <- st_as_sf(group_div1, wkt = 'fips_geom')

color_values <- list()
label_values <- list()

if (nrow(group_div1) >0) {
  
  geom1 <- geom_sf(data = group_div1, fill = color_scale[1],color = c_border, inherit.aes = FALSE)
  
  color_values <- color_scale[1]
  
  label_values <- paste(" <= ",div1,sep="")
  
} else  {
  
  geom1 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div1_div2 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div1," AND MGD_2020 <= ",div2)
group_div1_div2 <- sqldf(group_div1_div2)
group_div1_div2 <- st_as_sf(group_div1_div2, wkt = 'fips_geom')


if (nrow(group_div1_div2) >0) {
  
  geom2 <- geom_sf(data = group_div1_div2,fill = color_scale[2],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div1," to ",div2,sep=""))
  
} else  {
  
  geom2 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div2_div3 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div2," AND MGD_2020 <= ",div3)
group_div2_div3 <- sqldf(group_div2_div3)
group_div2_div3 <- st_as_sf(group_div2_div3, wkt = 'fips_geom')


if (nrow(group_div2_div3) >0) {
  
  geom3 <- geom_sf(data = group_div2_div3, fill = color_scale[3],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[3])
  label_values <- rbind(label_values,paste(div2," to ",div3,sep=""))
  
} else  {
  
  geom3 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div3_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div3," AND MGD_2020 <= ",div4)
group_div3_div4 <- sqldf(group_div3_div4)
group_div3_div4 <- st_as_sf(group_div3_div4, wkt = 'fips_geom')


if (nrow(group_div3_div4) >0) {
  
  geom4 <- geom_sf(data = group_div3_div4, fill = color_scale[4],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[4])
  label_values <- rbind(label_values,paste(div3," to ",div4,sep=""))
  
} else  {
  
  geom4 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
# group_div4_div5 <- paste("SELECT *
#                   FROM 'fips_geom.df'
#                   WHERE MGD_2020 > ",div4," AND MGD_2020 <= ",div5)
# group_div4_div5 <- sqldf(group_div4_div5)
# group_div4_div5 <- st_as_sf(group_div4_div5, wkt = 'fips_geom')
# 
# 
# if (nrow(group_div4_div5) >0) {
#   
#   geom5 <- geom_sf(data = group_div4_div5, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
#   
#   color_values <- rbind(color_values,color_scale[5])
#   label_values <- rbind(label_values,paste(div4," to ",div5,sep=""))
#   
# } else  {
#   
#   geom5 <- geom_blank()
#   
# }
# #-----------------------------------------------------------------------------------------------------
# group_div5_div6 <- paste("SELECT *
#                   FROM 'fips_geom.df'
#                   WHERE MGD_2020 > ",div5," AND MGD_2020 <= ",div6)
# group_div5_div6 <- sqldf(group_div5_div6)
# group_div5_div6 <- st_as_sf(group_div5_div6, wkt = 'fips_geom')
# 
# 
# if (nrow(group_div5_div6) >0) {
#   
#   geom6 <- geom_sf(data = group_div5_div6, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
#   
#   color_values <- rbind(color_values,color_scale[5])
#   label_values <- rbind(label_values,paste(div5," to ",div6,sep=""))
#   
# } else  {
#   
#   geom6 <- geom_blank()
#   
# }
# #-----------------------------------------------------------------------------------------------------
group_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 >= ",div4)
group_div4 <- sqldf(group_div4)
group_div4 <- st_as_sf(group_div4, wkt = 'fips_geom')


if (nrow(group_div4) >0) {
  
  geom5 <- geom_sf(data = group_div4, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[5])
  label_values <- rbind(label_values,paste(" >= ",div4,sep=""))
  
} else  {
  
  geom5 <- geom_blank()
  
}


####################################################################
source_current <- base_map +
  geom1 +
  geom2 +
  geom3 +
  geom4 +
  geom5 

#ggsave(plot = source_current, file =  paste0(folder, "JM_VA_locality_demand_map_TEST.png"), width=6.5, height=5) 

map <- ggdraw(source_current +
                ggtitle("Virginia Demand by Locality") +
                labs(subtitle = "2020 Demand (including Power Generation)") +
                
                #ADD MINOR BASIN BORDER LAYER ON TOP
                #geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.65) +
                #ADD STATE BORDER LAYER ON TOP
                geom_path(data = state.df,aes(x = long, y = lat, group = group), color="black",lwd=0.4) +
                #ADD VIRGINIA STATE BORDER LAYER ON TOP
                geom_sf(data = va_state_sf, fill = NA,color = "black", lwd=0.75, inherit.aes = FALSE) +
                #ADD RIVERS LAYER ON TOP
                geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
                #ADD BORDER 
                geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
                #ADD NORTH BAR
                north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                base_scale +
                base_theme) +
  deqlogo +
  base_legend
#map

print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
# ggsave(plot = map, file = export_file, width=5.5, height=5)
ggsave(plot = map, file = export_file, width=6.5, height=5)
beep(sound = 1)


############################################################################################
# SURFACE WATER MAP - 2020 DEMAND ##########################################################
############################################################################################
export_file <- paste0(folder, "tables_maps/Xfigures/VA_sw_2020_locality_demand_map.png")
#DEMAND TABLE 
va_demand <- read.csv(paste0(folder, "tables_maps/Xtables/VA_sw_locality_demand.csv"))
# #CUSTOM DIVS *NOTE* Currently the legend is not dynamic, but a static image
#div1 <- 0
div1 <- 10
div2 <- 50
div3 <- 100
div4 <- 500
#div6 <- 1000

color_scale <- c("#d98f50","#f7d679","#E4FFB9","darkolivegreen2","darkolivegreen")
### PROCESS FIPS GEOM LAYER  #####################################################################
fips_data <- paste('SELECT *
                  FROM "fips_geom.csv" AS a
                  LEFT OUTER JOIN va_demand AS b
                  ON (a.fips_code = b.fips_code)
                  WHERE a.fips_code LIKE "51%"
                     AND a.fips_code NOT LIKE "51685"
                  ',sep = '')

fips_layer <- sqldf(fips_data)
fips_layer[is.na(fips_layer)] <- 0.00
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

#LEFT TOP LEGEND
base_legend <- draw_image("U:/OWS/foundation_datasets/wsp/wsp2020/tables_maps/legend_locality_demand_2020_5bins.png",height = .35, x = -.38, y = .535) 

### #VA LOCALITY 2020 DEMAND - BREAK INTO BINS ##########################################
c_border <- 'gray30'

group_div1 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 <= ",div1)
group_div1 <- sqldf(group_div1)
group_div1 <- st_as_sf(group_div1, wkt = 'fips_geom')

color_values <- list()
label_values <- list()

if (nrow(group_div1) >0) {
  
  geom1 <- geom_sf(data = group_div1, fill = color_scale[1],color = c_border, inherit.aes = FALSE)
  
  color_values <- color_scale[1]
  
  label_values <- paste(" <= ",div1,sep="")
  
} else  {
  
  geom1 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div1_div2 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div1," AND MGD_2020 <= ",div2)
group_div1_div2 <- sqldf(group_div1_div2)
group_div1_div2 <- st_as_sf(group_div1_div2, wkt = 'fips_geom')


if (nrow(group_div1_div2) >0) {
  
  geom2 <- geom_sf(data = group_div1_div2,fill = color_scale[2],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div1," to ",div2,sep=""))
  
} else  {
  
  geom2 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div2_div3 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div2," AND MGD_2020 <= ",div3)
group_div2_div3 <- sqldf(group_div2_div3)
group_div2_div3 <- st_as_sf(group_div2_div3, wkt = 'fips_geom')


if (nrow(group_div2_div3) >0) {
  
  geom3 <- geom_sf(data = group_div2_div3, fill = color_scale[3],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[3])
  label_values <- rbind(label_values,paste(div2," to ",div3,sep=""))
  
} else  {
  
  geom3 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div3_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div3," AND MGD_2020 <= ",div4)
group_div3_div4 <- sqldf(group_div3_div4)
group_div3_div4 <- st_as_sf(group_div3_div4, wkt = 'fips_geom')


if (nrow(group_div3_div4) >0) {
  
  geom4 <- geom_sf(data = group_div3_div4, fill = color_scale[4],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[4])
  label_values <- rbind(label_values,paste(div3," to ",div4,sep=""))
  
} else  {
  
  geom4 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
# group_div4_div5 <- paste("SELECT *
#                   FROM 'fips_geom.df'
#                   WHERE MGD_2020 > ",div4," AND MGD_2020 <= ",div5)
# group_div4_div5 <- sqldf(group_div4_div5)
# group_div4_div5 <- st_as_sf(group_div4_div5, wkt = 'fips_geom')
# 
# 
# if (nrow(group_div4_div5) >0) {
#   
#   geom5 <- geom_sf(data = group_div4_div5, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
#   
#   color_values <- rbind(color_values,color_scale[5])
#   label_values <- rbind(label_values,paste(div4," to ",div5,sep=""))
#   
# } else  {
#   
#   geom5 <- geom_blank()
#   
# }
# #-----------------------------------------------------------------------------------------------------
# group_div5_div6 <- paste("SELECT *
#                   FROM 'fips_geom.df'
#                   WHERE MGD_2020 > ",div5," AND MGD_2020 <= ",div6)
# group_div5_div6 <- sqldf(group_div5_div6)
# group_div5_div6 <- st_as_sf(group_div5_div6, wkt = 'fips_geom')
# 
# 
# if (nrow(group_div5_div6) >0) {
#   
#   geom6 <- geom_sf(data = group_div5_div6, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
#   
#   color_values <- rbind(color_values,color_scale[5])
#   label_values <- rbind(label_values,paste(div5," to ",div6,sep=""))
#   
# } else  {
#   
#   geom6 <- geom_blank()
#   
# }
# #-----------------------------------------------------------------------------------------------------
group_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 >= ",div4)
group_div4 <- sqldf(group_div4)
group_div4 <- st_as_sf(group_div4, wkt = 'fips_geom')


if (nrow(group_div4) >0) {
  
  geom5 <- geom_sf(data = group_div4, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[5])
  label_values <- rbind(label_values,paste(" >= ",div4,sep=""))
  
} else  {
  
  geom5 <- geom_blank()
  
}


####################################################################
source_current <- base_map +
  geom1 +
  geom2 +
  geom3 +
  geom4 +
  geom5 

#ggsave(plot = source_current, file =  paste0(folder, "JM_VA_locality_demand_map_TEST.png"), width=6.5, height=5) 

map <- ggdraw(source_current +
                ggtitle("Virginia Surface Water Demand by Locality") +
                labs(subtitle = "2020 Demand (including Power Generation)") +
                
                #ADD MINOR BASIN BORDER LAYER ON TOP
                #geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.65) +
                #ADD STATE BORDER LAYER ON TOP
                geom_path(data = state.df,aes(x = long, y = lat, group = group), color="black",lwd=0.4) +
                #ADD VIRGINIA STATE BORDER LAYER ON TOP
                geom_sf(data = va_state_sf, fill = NA,color = "black", lwd=0.75, inherit.aes = FALSE) +
                #ADD RIVERS LAYER ON TOP
                geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
                #ADD BORDER 
                geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
                #ADD NORTH BAR
                north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                base_scale +
                base_theme) +
  deqlogo +
  base_legend
#map

print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
# ggsave(plot = map, file = export_file, width=5.5, height=5)
ggsave(plot = map, file = export_file, width=6.5, height=5)
beep(sound = 1)



############################################################################################
# GROUNDWATER MAP - 2020 DEMAND ############################################################
############################################################################################
export_file <- paste0(folder, "tables_maps/Xfigures/VA_gw_2020_locality_demand_map2.png")
#DEMAND TABLE 
va_demand <- read.csv(paste0(folder, "tables_maps/Xtables/VA_gw_locality_demand.csv"))
# #CUSTOM DIVS *NOTE* Currently the legend is not dynamic, but a static image
#div1 <- 0
div1 <- 0.5
div2 <- 1
div3 <- 5
div4 <- 10
div5 <- 15

color_scale <- c("#d98f50","#f7d679","#E4FFB9","darkolivegreen2","darkolivegreen3","darkolivegreen")
### PROCESS FIPS GEOM LAYER  #####################################################################
fips_data <- paste('SELECT *
                  FROM "fips_geom.csv" AS a
                  LEFT OUTER JOIN va_demand AS b
                  ON (a.fips_code = b.fips_code)
                  WHERE a.fips_code LIKE "51%"
                     AND a.fips_code NOT LIKE "51685"
                  ',sep = '')

fips_layer <- sqldf(fips_data)
fips_layer[is.na(fips_layer)] <- 0.00
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

# NEED TO REMOVE SECOND "hydrocode" COLUMN TO PREVENT ERROR LATER ON
fips_geom.df <- fips_geom.df[,-which(colnames(fips_geom.df)=="fips_code..8" )]

# REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
fips_geom.df.sql <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE fips_geom != ''")  
fips_geom.df <- sqldf(fips_geom.df.sql)
#print(length(fips_geom.df[,1]))



#LEFT TOP LEGEND
base_legend <- draw_image("U:/OWS/foundation_datasets/wsp/wsp2020/tables_maps/legend_locality_demand_2020_gw.png",height = .35, x = -.38, y = .515) 


### #VA LOCALITY GW 2020 DEMAND - BREAK INTO BINS ##########################################
c_border <- 'gray30'

group_div1 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 <= ",div1)
group_div1 <- sqldf(group_div1)
group_div1 <- st_as_sf(group_div1, wkt = 'fips_geom')

color_values <- list()
label_values <- list()

if (nrow(group_div1) >0) {
  
  geom1 <- geom_sf(data = group_div1, fill = color_scale[1],color = c_border, inherit.aes = FALSE)
  
  color_values <- color_scale[1]
  
  label_values <- paste(" <= ",div1,sep="")
  
} else  {
  
  geom1 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div1_div2 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div1," AND MGD_2020 <= ",div2)
group_div1_div2 <- sqldf(group_div1_div2)
group_div1_div2 <- st_as_sf(group_div1_div2, wkt = 'fips_geom')


if (nrow(group_div1_div2) >0) {
  
  geom2 <- geom_sf(data = group_div1_div2,fill = color_scale[2],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div1," to ",div2,sep=""))
  
} else  {
  
  geom2 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div2_div3 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div2," AND MGD_2020 <= ",div3)
group_div2_div3 <- sqldf(group_div2_div3)
group_div2_div3 <- st_as_sf(group_div2_div3, wkt = 'fips_geom')


if (nrow(group_div2_div3) >0) {
  
  geom3 <- geom_sf(data = group_div2_div3, fill = color_scale[3],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[3])
  label_values <- rbind(label_values,paste(div2," to ",div3,sep=""))
  
} else  {
  
  geom3 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div3_div4 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div3," AND MGD_2020 <= ",div4)
group_div3_div4 <- sqldf(group_div3_div4)
group_div3_div4 <- st_as_sf(group_div3_div4, wkt = 'fips_geom')


if (nrow(group_div3_div4) >0) {
  
  geom4 <- geom_sf(data = group_div3_div4, fill = color_scale[4],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[4])
  label_values <- rbind(label_values,paste(div3," to ",div4,sep=""))
  
} else  {
  
  geom4 <- geom_blank()
  
}
# #-----------------------------------------------------------------------------------------------------
group_div4_div5 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 > ",div4," AND MGD_2020 <= ",div5)
group_div4_div5 <- sqldf(group_div4_div5)
group_div4_div5 <- st_as_sf(group_div4_div5, wkt = 'fips_geom')


if (nrow(group_div4_div5) >0) {
  
  geom5 <- geom_sf(data = group_div4_div5, fill = color_scale[5],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[5])
  label_values <- rbind(label_values,paste(div4," to ",div5,sep=""))
  
} else  {
  
  geom5 <- geom_blank()
  
}
# # #-----------------------------------------------------------------------------------------------------
# group_div5_div6 <- paste("SELECT *
#                   FROM 'fips_geom.df'
#                   WHERE MGD_2020 > ",div5," AND MGD_2020 <= ",div6)
# group_div5_div6 <- sqldf(group_div5_div6)
# group_div5_div6 <- st_as_sf(group_div5_div6, wkt = 'fips_geom')
# 
# 
# if (nrow(group_div5_div6) >0) {
#   
#   geom6 <- geom_sf(data = group_div5_div6, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
#   
#   color_values <- rbind(color_values,color_scale[5])
#   label_values <- rbind(label_values,paste(div5," to ",div6,sep=""))
#   
# } else  {
#   
#   geom6 <- geom_blank()
#   
# }
# #-----------------------------------------------------------------------------------------------------
group_div5 <- paste("SELECT *
                  FROM 'fips_geom.df'
                  WHERE MGD_2020 >= ",div5)
group_div5 <- sqldf(group_div5)
group_div5 <- st_as_sf(group_div5, wkt = 'fips_geom')


if (nrow(group_div5) >0) {
  
  geom6 <- geom_sf(data = group_div5, fill = color_scale[6],color = c_border, inherit.aes = FALSE)
  
  color_values <- rbind(color_values,color_scale[6])
  label_values <- rbind(label_values,paste(" >= ",div5,sep=""))
  
} else  {
  
  geom6 <- geom_blank()
  
}


####################################################################
source_current <- base_map +
  geom1 +
  geom2 +
  geom3 +
  geom4 +
  geom5 +
  geom6 

#ggsave(plot = source_current, file =  paste0(folder, "JM_VA_locality_demand_map_TEST.png"), width=6.5, height=5) 

map <- ggdraw(source_current +
                ggtitle("Virginia Groundwater Demand by Locality") +
                labs(subtitle = "2020 Demand (including Power Generation)") +
                
                #ADD MINOR BASIN BORDER LAYER ON TOP
                #geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.65) +
                #ADD STATE BORDER LAYER ON TOP
                geom_path(data = state.df,aes(x = long, y = lat, group = group), color="black",lwd=0.4) +
                #ADD VIRGINIA STATE BORDER LAYER ON TOP
                geom_sf(data = va_state_sf, fill = NA,color = "black", lwd=0.75, inherit.aes = FALSE) +
                #ADD RIVERS LAYER ON TOP
                geom_path(data = rivs.df, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4) +
                #ADD BORDER 
                geom_polygon(data = bbDF,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)+
                #ADD NORTH BAR
                north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
                base_scale +
                base_theme) +
  deqlogo +
  base_legend
#map

print(paste("GENERATED MAP CAN BE FOUND HERE: ",export_file,sep=""))
# ggsave(plot = map, file = export_file, width=5.5, height=5)
ggsave(plot = map, file = export_file, width=6.5, height=5)
beep(sound = 1)
