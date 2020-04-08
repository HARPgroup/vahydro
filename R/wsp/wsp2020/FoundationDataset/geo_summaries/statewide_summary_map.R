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

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
rseg_l30_results <- read.csv(paste(folder,"metrics_watershed_l30_Qout.csv",sep=""))
#rseg_shp <- readOGR(dsn = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/VAHydro_Rsegs.gdb', layer = 'VAHydro_RSegs')
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
#RSeg_data <- RSeg.csv

RSeg_data <- sqldf("SELECT *
                    FROM 'RSeg.csv'
                    WHERE hydrocode LIKE '%PS%'")

RSeg_data$id <- as.character(row_number(RSeg_data$hydrocode))
RSeg.list <- list()

#r<-1
for (r in 1:length(RSeg_data$hydrocode)) {
  print(paste("r = ",r," of ",length(RSeg_data$hydrocode),sep=''))
  print(as.character(RSeg_data$hydrocode[r]))
  #RSeg_geom <- readWKT(RSeg_data$geom[r])
  if (as.character(RSeg_data$geom[r]) == "") {print('Invalid Geom, Skipping...')
  } else {
    RSeg_geom <- readWKT(RSeg_data$geom[r]) 
  }

  RSeg_geom_clip <- gIntersection(bb, RSeg_geom)
  RSegProjected <- SpatialPolygonsDataFrame(RSeg_geom_clip, data.frame('id'), match.ID = TRUE)
  RSegProjected@data$id <- as.character(r)
  RSeg.list[[r]] <- RSegProjected
}
RSeg <- do.call('rbind', RSeg.list)
RSeg@data <- merge(RSeg@data, RSeg_data, by = 'id')
RSeg@data <- RSeg@data[,-c(2:3)]
RSeg.df <- fortify(RSeg, region = 'id')
RSeg.df <- merge(RSeg.df, RSeg@data, by = 'id')



######################################################################################################
### PROCESS l30
######################################################################################################
rseg_l30_df <- sqldf("SELECT *,
    round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_13,
    round(((b.runid_15 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_15,
    round(((b.runid_16 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_16,
    round(((b.runid_18 - b.runid_11) / b.runid_11) * 100,2) AS chg_11_to_18
                      FROM 'RSeg.df' a
                      LEFT OUTER JOIN rseg_l30_results b
                      ON a.hydrocode = b.hydrocode")
#head(rseg_l30_df)

######################################################################################################
### GENERATE YOUR MAP  ###############################################################################
######################################################################################################

#options(scipen=999) #remove scientific notation from map legend

#SET UP BASE MAP
base_map  <- ggplot(data = state.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5)


model_l30_map <- base_map +
  geom_polygon(data = rseg_l30_df, aes(x = long, y = lat, fill = chg_11_to_13), color='black') +
  scale_fill_gradientn(
    limits = c(-20,23),
    labels = c('>= 0%','-5 to 0%','-10% to -5%', '-20% to -10%', 'More Than -20%'),
    breaks =  c(23,0,-5,-10,-20),
    colors = c("red","purple","blue","green","yellow"),
    space ="Lab", name = "20 Year \n % Change",
    guide = guide_colourbar(
      direction = "vertical",
      title.position = "top",
      label.position = "left")) +
  geom_polygon(data = MB.df,fill = NA, color = 'dodgerblue4', size = 1) +
  labs(subtitle = "model_l30_map")

ggsave(plot = model_l30_map, file = paste0(folder, "state_plan_figures/statewide/model_l30_11vs13_map.png"), width=6.5, height=5)



