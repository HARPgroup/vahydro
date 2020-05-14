library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma
library(cowplot) #plot static legend and DEQ logo

######################################################################################################
### LOAD LAYERS  #####################################################################################
######################################################################################################
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
RSeg.csv <- read.table(file = paste(hydro_tools_location,'/GIS_LAYERS/VAHydro_RSegs.csv', sep = ''), sep = ',', header = TRUE)


runid_a <- "runid_11"
runid_b <- "runid_13"

#Metric options include "7q10", "l30_Qout", "l90_Qout"
metric <- "l30_Qout"

plot_title <- paste("Percent Change in ",metric," (",runid_a," to ",runid_b,")",sep="")

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))

export_path <- folder
#export_path <- paste(vahydro_location,"/R/wsp/wsp2020/FoundationDataset/geo_summaries/temp_output/",sep="")
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
                  ON (a.hydrocode = b.hydrocode)',sep = '') 
                  #WHERE a.hydrocode LIKE "%wshed_',minorbasin,'%"',sep = '') 
RSeg_data <- sqldf(RSeg_data)
length(RSeg_data[,1])
RSeg_data <- RSeg_data[,-5] #need to remove duplicate hydrocode column? 
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
                  WHERE pct_chg >= 0")  
group_0_plus <- sqldf(group_0_plus)
group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg5_0 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < 0 AND pct_chg >= -5")  
group_neg5_0 <- sqldf(group_neg5_0)
group_neg5_0 <- st_as_sf(group_neg5_0, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg10_neg5 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < -5 AND pct_chg >= -10")  
group_neg10_neg5 <- sqldf(group_neg10_neg5)
group_neg10_neg5 <- st_as_sf(group_neg10_neg5, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_neg20_neg10 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg < -10 AND pct_chg >= -20")  
group_neg20_neg10 <- sqldf(group_neg20_neg10)
group_neg20_neg10 <- st_as_sf(group_neg20_neg10, wkt = 'geom')
#-----------------------------------------------------------------------------------------------------
group_negInf_neg20 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE pct_chg <= -20")  
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
  
  draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 2, height = 1, x = extent$x[1]+0.56, y = extent$y[1])+ 
  
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

ggsave(plot = map, file = paste0(export_path, "tables_maps/statewide/chg_",runid_a,"_to_",runid_b,"_",metric,"_map.png"), width=6.5, height=5)



