library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

######################################################################################################
### LOAD LAYERS  #####################################################################################
######################################################################################################
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
RSeg <- read.table(file = paste(folder,'/VAHydro_RSegs.csv', sep = ''), sep = ',', header = TRUE)

data_rseg_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
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
### PROCESS River Segment LAYER  #####################################################################
######################################################################################################

 # REMOVE ANY OF INTEREST
 
  #REMOVE HYDROPOWER
  data_rseg_nohydro <-  data_rseg_raw
  with_hydro <- length(data_rseg_nohydro[,1])
  rseg_nohydro <- paste("SELECT *
                  FROM data_rseg_nohydro
                  WHERE facility_ftype != 'hydropower'")  
  rseg_nohydro <- sqldf(rseg_nohydro)
  without_hydro <- length(rseg_nohydro[,1])
  print(paste('Number of hydropower facilities removed: ',with_hydro-without_hydro,sep=''))

  data_rseg <- data_rseg_nohydro
  #data_rseg <- data_rseg_raw
######################################################################################################

# SUMMARIZE DATA BY VAHYDRO RIVER SEGMENT
RSeg.sql <- paste("SELECT VAHydro_RSeg_Name,
              VAHydro_RSeg_Code,
              COUNT(MP_hydroid),
              sum(mp_2020_mgy) AS mgy_2020,
              sum(mp_2040_mgy) AS mgy_2040
              FROM data_rseg 
              GROUP BY VAHydro_RSeg_Code
              ",sep="")
RSeg_summary <- sqldf(RSeg.sql)
######################################################################################################

  # REMOVE SUPER LARGE VALUES - FOR QA PURPOSES ONLY
  # with_lg <- length(RSeg_summary[,1])
  # summary_sort <- paste("SELECT *
  #                   FROM RSeg_summary
  #                   WHERE mgy_2020 < 200000
  #                   ORDER BY mgy_2020 DESC")
  # summary_sort <- sqldf(summary_sort)
  # RSeg_summary <- summary_sort
  # without_lg <- length(RSeg_summary[,1])
  # print(paste('Number of large values removed: ',with_lg-without_lg,sep=''))
  # 
######################################################################################################
RSeg_raw <- RSeg
  length(RSeg_raw[,1])

  
# JOIN DATA BY RIVER SEGMENT TO RIVER SEGMENT GEOMETRY LAYER
RSeg_data <- paste("SELECT *
                  FROM RSeg AS a
                  LEFT OUTER JOIN RSeg_summary AS b
                  ON (a.hydrocode = b.VAHydro_RSeg_Code)")  
RSeg_data <- sqldf(RSeg_data)
  length(RSeg_data[,1])

# REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
RSeg_data <- sqldf(RSeg_valid_geoms)
  length(RSeg_data[,1])

######################################################################################################
RSeg_data <- st_as_sf(RSeg_data, wkt = 'geom')
######################################################################################################

######################################################################################################
### GENERATE YOUR MAP  ###############################################################################
######################################################################################################

options(scipen=999) #remove scientific notation from map legend

#SET UP BASE MAP
base_map  <- ggplot(data = state.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5)

#ADD LAYER OF INTEREST
map <- base_map + 
  #no group on this layer, so don't inherit aes
  geom_sf(data = RSeg_data,aes(geometry = geom,fill = mgy_2040), inherit.aes = FALSE)+ 
  geom_polygon(data = MB.df, color="black", fill = NA,lwd=0.5)+
  geom_point(data = data_rseg_raw, aes(x = corrected_longitude, y = corrected_latitude,group = 123), size = 1, shape = 20, fill = "darkblue")+

  guides(fill=guide_colorbar(title="Legend\n2020 (MGY)")) +
  scale_fill_gradient2(low = 'white',high = 'blue',
                         labels=function(x) format(x, big.mark = ",", scientific = FALSE),
                         trans = "log10") +
  theme(legend.justification=c(0,1), legend.position=c(0,1)) +
  xlab('Longitude (deg W)') + ylab('Latitude (deg N)')+
  north(bbDF, location = 'topright', symbol = 12, scale=0.1)+
  scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'mi', 
           transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
           st.size = 3.5, st.dist = 0.0285,
           anchor = c(
             x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-2.0,
             y = extent$y[1]+(extent$y[1])*0.001
           ))

ggsave(plot = map, file = paste0(folder, "state_plan_figures/2040_RSeg_MP.png"), width=6.5, height=5)

#----------------------------------------------------------------------------
# 
# summary_sort <- paste("SELECT *
#                   FROM RSeg_summary
#                   ORDER BY mgy_2020 DESC") 
# summary_sort <- sqldf(summary_sort)
# summary_sort
# colnames(summary_sort)
# 
# ######################################################################################################
# ######################################################################################################
# ######################################################################################################
# # OUTPUT TABLE IN KABLE FORMAT
# kable(summary_sort, "latex", booktabs = T,
#       caption = paste("River Segment",sep=""), 
#       label = paste("RiverSegment",sep=""),
#       col.names = c("River Segment Name",
#                     "River Segment Code",
#                     "Facility Count",
#                     "2020 (MGY)",
#                     "2040 (MGY)")) %>%
#   kable_styling(bootstrap_options = c("striped", "scale_down")) %>% 
#   #column_spec(1, width = "5em") %>%
#   #column_spec(2, width = "5em") %>%
#   #column_spec(3, width = "5em") %>%
#   #column_spec(4, width = "4em") %>%
#   cat(., file = paste(folder,"kable_tables/RiverSegment_statewide_kable.tex",sep=""))
