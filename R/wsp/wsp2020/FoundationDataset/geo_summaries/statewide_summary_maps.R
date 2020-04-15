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
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
RSeg.csv <- read.table(file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/VAHydro_RSegs.csv', sep = ',', header = TRUE)

#Metric options include "7q10", "l30_Qout", "l90_Qout"
metric <- "l90_Qout"
plot_title <- "90 Day Low Flow (Percent Change 2020 to Exempt Users Run)"

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
######################################################################################################

#specify spatial extent for map  
extent <- data.frame(x = c(-84, -75), 
                     y = c(35, 41))  

#bounding box
bb=readWKT(paste0("POLYGON((",extent$x[1]," ",extent$y[1],",",extent$x[2]," ",extent$y[1],",",extent$x[2]," ",extent$y[2],",",extent$x[1]," ",extent$y[2],",",extent$x[1]," ",extent$y[1],"))",sep=""))
bbProjected <- SpatialPolygonsDataFrame(bb,data.frame("id"), match.ID = FALSE)
bbProjected@data$id <- rownames(bbProjected@data)
bbPoints <- fortify(bbProjected, region = "id")
bbDF <- merge(bbPoints, bbProjected@data, by = "id")

######################################################################################################
### PROCESS STATES LAYER  ############################################################################
######################################################################################################

#Need to remove Indiana due to faulty geom
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
                  ON (a.hydrocode = b.hydrocode)")  
RSeg_data <- sqldf(RSeg_data)
length(RSeg_data[,1])

# REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
RSeg_data <- sqldf(RSeg_valid_geoms)
length(RSeg_data[,1])

######################################################################################################
######################################################################################################
#colnames(RSeg_data)
group_0_plus <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_18 >= 0")  
group_0_plus <- sqldf(group_0_plus)
group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg5_0 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_18 < 0 AND chg_11_to_18 >= -5")  
group_neg5_0 <- sqldf(group_neg5_0)
group_neg5_0 <- st_as_sf(group_neg5_0, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg10_neg5 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_18 < -5 AND chg_11_to_18 >= -10")  
group_neg10_neg5 <- sqldf(group_neg10_neg5)
group_neg10_neg5 <- st_as_sf(group_neg10_neg5, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg20_neg10 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_18 < -10 AND chg_11_to_18 >= -20")  
group_neg20_neg10 <- sqldf(group_neg20_neg10)
group_neg20_neg10 <- st_as_sf(group_neg20_neg10, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_negInf_neg20 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_18 <= -20")  
group_negInf_neg20 <- sqldf(group_negInf_neg20)
group_negInf_neg20 <- st_as_sf(group_negInf_neg20, wkt = 'geom')
######################################################################################################

######################################################################################################
RSeg_data <- st_as_sf(RSeg_data, wkt = 'geom')
######################################################################################################

######################################################################################################
### GENERATE YOUR MAP  ###############################################################################
######################################################################################################
#SET UP BASE MAP
base_map  <- ggplot(data = state.df, aes(x = long, y = lat, group = group)) +
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5) +
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5) + 
  ggsn::scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'mi',
           transform = TRUE, model = 'WGS84',st.bottom=FALSE,
           st.size = 3.5, st.dist = 0.0285,
           anchor = c(
             x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-2.0,
             y = extent$y[1]+(extent$y[1])*0.001
           )) +
  xlab('Longitude (deg W)') + ylab('Latitude (deg N)')+
  north(bbDF, symbol = 3, scale=0.12,
        anchor = c(
          x = extent$x[2],
          y = extent$y[2]-(0.002*extent$y[2])
        )) +
  #no group on this layer, so don't inherit aes
  geom_sf(data = RSeg_data,aes(geometry = geom,fill = 'aliceblue'), inherit.aes = FALSE,  show.legend=FALSE)

#colnames(RSeg_data)
map <- base_map + 
  geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'antiquewhite1'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'antiquewhite2'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'antiquewhite3'), inherit.aes = FALSE)+ 
  geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'antiquewhite4'), inherit.aes = FALSE)+ 

    scale_fill_manual(values=c("gray55","darkolivegreen3","cornflowerblue","khaki2","plum3","coral3"), 
                    name = "Legend",
                    labels = c("In Progress",
                               ">= 0%", 
                               "-5% to 0%", 
                               "-10% to -5%", 
                               "-20% to -10%", 
                               "More than -20%"))+
  guides(fill = guide_legend(reverse=TRUE))+
  geom_polygon(data = MB.df, color="black", fill = NA,lwd=0.5)+
  ggtitle(plot_title)+
  theme(legend.justification=c(0,1), legend.position=c(0,1)) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        panel.border = element_blank())

ggsave(plot = map, file = paste0(folder, "state_plan_figures/statewide/chg_11_to_18_",metric,"_map.png"), width=6.5, height=5)



