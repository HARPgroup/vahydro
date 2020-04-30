library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma
library(wicket) #wkt_centroid() 
library(cowplot) #plot static legend
library(magick) #plot static legend
library(tictoc) #time elapsed
 ######################################################################################################
### USER INPUTS  #####################################################################################
######################################################################################################

minorbasin <- "RL" #PS, NR, YP, TU, RL, OR, EL, ES, PU, RU, YM, JA, MN, PM, YL, BS, PL, OD, JU, JB, JL
#MinorBasins.csv[,2:3]

#Metric options include "7q10", "l30_Qout", "l90_Qout"
metric <- "l30_Qout"

#runids
runid_a <- "runid_11"
runid_b <- "runid_13"

######################################################################################################
######################################################################################################

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
RSeg.csv <- read.table(file = paste(hydro_tools_location,'/GIS_LAYERS/VAHydro_RSegs.csv', sep = ''), sep = ',', header = TRUE)
river_shp <- readOGR(paste(hydro_tools_location,'/GIS_LAYERS/MajorRivers',sep = ''), "MajorRivers")

rseg_map_function <- function(MinorBasin_Code,metric,runid_a,runid_b,mp_points = FALSE){
#selects minor basin name
mb_name <-sqldf(paste('SELECT name
              FROM "MinorBasins.csv" 
              WHERE code == "',minorbasin,'"',sep=""))

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
                              runid_b == "runid_18" ~ "Exempt Users")

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
    print(paste("i = ",i,sep=''))
    print(as.character(STATES$state[i]))
    state_geom <- readWKT(STATES$geom[i])
    #print(state_geom)
    state_geom_clip <- gIntersection(bb, state_geom)
    
    if (is.null(state_geom_clip) == TRUE) {
      print("STATE OUT OF MINOR BASIN EXTENT - SKIPPING") 
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
#####################################################################################################
#summary(river_shp)
#plot(river_shp)
proj4string(MBProjected) <- CRS("+proj=longlat +datum=WGS84")
MBProjected <- spTransform(MBProjected, CRS("+proj=longlat +datum=WGS84"))
river_shpProjected <- spTransform(river_shp, CRS("+proj=longlat +datum=WGS84"))
river_clip <- gIntersection(MBProjected,river_shpProjected)
river.df <- sp::SpatialLinesDataFrame(river_clip, data.frame('id'), match.ID = TRUE)
#summary(river.df)

######################################################################################################
### PROCESS RSegs
######################################################################################################
# JOIN DATA BY RIVER SEGMENT TO RIVER SEGMENT GEOMETRY LAYER
RSeg_data <- paste('SELECT *,
                  case
                  when b.',runid_a,' = 0
                  then 0
                  else round(((b.',runid_b,' - b.',runid_a,') / b.',runid_a,') * 100,2)
                  end AS pct_chg
                  FROM "RSeg.csv" AS a
                  LEFT OUTER JOIN RSeg_summary AS b
                  ON (a.hydrocode = b.hydrocode)
                  WHERE a.hydrocode LIKE "%wshed_',minorbasin,'%"',sep = '')  


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
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5) +
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5)

base_river <- geom_line(data = river.df,aes(x=long,y=lat, group=group), inherit.aes = FALSE,  show.legend=FALSE, color = 'royalblue4', size = .5)

base_scale <-  ggsn::scalebar(data = bbDF, location = 'bottomright', dist = 25, dist_unit = 'mi', 
                              transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
                              st.size = 3, st.dist = 0.03,
                              anchor = c(
                                x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])+0.9,
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
if (minorbasin %in% c('BS','JA','NR','OR','PL','RL','YL','YM','YP')) {
  
  image_path <- paste(folder, 'tables_maps/legend_rseg_tidal_segment.PNG',sep='')
  
} else {
  image_path <- paste(folder, 'tables_maps/legend_rseg.PNG',sep='')
}
#select the legend position based on how much marginal space each minorbasin has around it
if (minorbasin %in% c('RL','YM','YP','JB','YL','OR','PL')) {
  base_legend <- draw_image(image_path,height = .32, x = -.2, y = .05)
} else  {
  base_legend <- draw_image(image_path,height = .32, x = -.25, y = .551)
}  
######################################################################################################
#colnames(RSeg_data)
group_0_plus <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg >= 0")  
group_0_plus <- sqldf(group_0_plus)
group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')

if (nrow(group_0_plus) >0) {
  
  geom1 <- geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)
  color_values <- "darkolivegreen3"
  label_values <- ">= 0%"
  
} else  {
  # geom1 <- geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)
  # color_values <- "gray40"
  # label_values <- "Tidal Segment"
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
  # geom2 <- geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'gray'), inherit.aes = FALSE)
  # color_values <- rbind(color_values,"gray40")
  # label_values <- rbind(label_values,"Tidal Segment")
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
  
  # geom3 <- geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'gray01'), inherit.aes = FALSE)
  # color_values <- rbind(color_values,"gray40")
  # label_values <- rbind(label_values,"Tidal Segment")
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
  
  # geom4 <- geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'gray03'), inherit.aes = FALSE)
  # color_values <- rbind(color_values,"gray40")
  # label_values <- rbind(label_values,"Tidal Segment")
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
  
  # geom5 <- geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'gray04'), inherit.aes = FALSE)
  # color_values <- rbind(color_values,"gray40")
  # label_values <- rbind(label_values,"Tidal Segment")
  geom5 <- geom_blank()
  
}

#create a geom_sf for the tidal segments that are plotted a default color
if (
  any(nrow(group_0_plus) == 0,nrow(group_neg5_0) == 0,nrow(group_neg10_neg5) == 0,nrow(group_neg20_neg10) == 0,nrow(group_negInf_neg20) == 0) == TRUE) {
  group_tidal <- st_as_sf(RSeg_data, wkt = 'geom')
  geom_tidal <- geom_sf(data = group_tidal,aes(geometry = geom,fill = 'gray04'), inherit.aes = FALSE)
  color_values <- rbind(color_values,"gray40")
  label_values <- rbind(label_values,"Tidal Segment")
}  else  {
  
  geom5 <- geom_blank()
  
} 
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

map <- ggdraw(source_current +
  geom_polygon(data = MB.df,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5) +
  ggtitle(paste(metric_title," (Percent Change ",scenario_a_title," to ",scenario_b_title,")",sep = '')) +
  labs(subtitle = mb_name$name) +
  #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
  north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
  base_river +
  base_scale +
  base_theme) +
  base_legend

map

ggsave(plot = map, file = paste0(folder, "tables_maps/",mb_name$name,"/",runid_a,"_to_",runid_b,"_",metric,"_",minorbasin,"_map.png",sep = ""), width=6.5, height=5)
}

#------------------------------------------------------
# ##empty basemap for plotting points with no rseg background
# q <- ggdraw(base_map +
#   ggtitle(paste(metric_title," (Percent Change ",scenario_a_title," to ",scenario_b_title,")",sep = '')) +
#   #xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
#   north(bbDF, location = 'topright', symbol = 3, scale=0.12) +
#   base_river +
#   base_scale +
#   base_theme +
#   labs(subtitle = mb_name$name)) +
#   draw_image(paste(folder, 'state_plan_figures/single_basin/Legend_nodata.png',sep=''),height = .33, x = -.352, y = .55) 
# 
# ggsave(plot = q, file = paste0(folder, "state_plan_figures/single_basin/",runid_a,"_to_",runid_b,"_",metric,"_",minorbasin,"_map_legend_test.png",sep = ""), width=6.5, height=5)



#----------- RUN MAPS IN BULK --------------------------

minorbasin <- "JU" #PS, NR, YP, TU, RL, OR, EL, ES, PU, RU, YM, JA, MN, PM, YL, BS, PL, OD, JU, JB, JL

#runids
runid_a <- "runid_11"
runid_b <- "runid_18"

m <- c("7q10", "l30_Qout", "l90_Qout")
r <- c("runid_13","runid_15","runid_16","runid_18") 

m <- c("l30_Qout")
r <- c("runid_13") 

tic("Total")
for (i in m) {
  tic(paste("Metric - ",i))
  print(paste("Metric:",i,"has started"))
  for (z in r) {
    tic(paste("Scenario - ",z))
    print(paste("Scenario:",z,"has started"))
    rseg_map_function(minorbasin,i,runid_a,z) 
    print(paste("Scenario:",z,"has been completed"))
    toc()
  }
  print(paste("Metric:",i,"has been completed"))
  toc()
}
toc()

