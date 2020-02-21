library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)

#--------------------------------------------------------------------------------------------
#LOAD POLYGON LAYERS
#--------------------------------------------------------------------------------------------
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
huc6.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/HUC6.tsv', sep = '\t', header = TRUE)

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_huc_raw <- read.csv(paste(folder,"wsp2020.fac.all.HUC.csv",sep=""))
#--------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------

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
######################################################################################################
######################################################################################################
#STATES LOOP

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
######################################################################################################
######################################################################################################
HUC6.sql <- paste('SELECT HUC6_Name,
              HUC6_Code,
              COUNT(Facility_hydroid),
              sum(fac_2020_mgy) AS mgy_2020,
              sum(fac_2040_mgy) AS mgy_2040
              FROM data_huc_raw 
              GROUP BY HUC6_Code
              ',sep="")
HUC6_summary <- sqldf(HUC6.sql)
###########################################################################
###########################################################################
huc6_df <- huc6.csv

st_data <- paste("SELECT *
                  FROM huc6_df AS a
                  LEFT OUTER JOIN HUC6_summary AS b
                  ON (a.HUC6 = b.HUC6_Code)")  
st_data <- sqldf(st_data)

st_data$id <- as.character(row_number(st_data$HUC6))
huc6.list <- list()

for (z in 1:length(st_data$HUC6)) {
print(paste("z = ",z,sep=''))
print(st_data$HUC6[z])
  huc6_geom <- readWKT(st_data$geom[z])
#print(huc6_geom)
  huc6_geom_clip <- gIntersection(bb, huc6_geom)
  huc6Projected <- SpatialPolygonsDataFrame(huc6_geom_clip, data.frame('id'), match.ID = TRUE)
  huc6Projected@data$id <- as.character(z)
  huc6.list[[z]] <- huc6Projected
}

huc6 <- do.call('rbind', huc6.list)
huc6@data <- merge(huc6@data, st_data, by = 'id')
huc6@data <- huc6@data[,-c(2:3)]
huc6.df <- fortify(huc6, region = 'id')
huc6.df <- merge(huc6.df, huc6@data, by = 'id')
######################################################################################################
######################################################################################################
#SET UP BASE MAP
map <- ggplot(data = huc6.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5)

#ADD LAYER OF INTEREST
map + 
  geom_polygon(aes(fill = mgy_2040), color = 'black', size = 0.1, alpha = 0.25) +
  guides(fill=guide_colorbar(title="Legend\n2040 (MGY) By HUC6")) +
  theme(legend.justification=c(0,1), legend.position=c(0,1)) +
  xlab('Longitude (deg W)') + ylab('Latitude (deg N)')+
  #scale_fill_gradient2(low = 'brown', mid = 'white', high = 'blue') +
  scale_fill_gradient2(low = 'brown', mid = 'white', high = 'blue',
                       labels=function(x) format(x, big.mark = ",", scientific = FALSE)) +
  north(bbDF, location = 'topright', symbol = 12, scale=0.1)+
  scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'km', 
           transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
           st.size = 3.5, st.dist = 0.0285,
           anchor = c(
             x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-1.1,
             y = extent$y[1]+(extent$y[1])*0.001
           ))

HUC6_summary
