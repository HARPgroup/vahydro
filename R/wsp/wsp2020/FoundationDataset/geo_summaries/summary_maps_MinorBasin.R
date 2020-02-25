library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)

#--------------------------------------------------------------------------------------------
#LOAD POLYGON LAYERS
#--------------------------------------------------------------------------------------------
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)



folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_minorbasin_raw <- read.csv(paste(folder,"wsp2020.fac.all.MinorBasins.csv",sep=""))
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
MB.sql <- paste('SELECT HUC6_Name,
              MinorBasin_Name,
              MinorBasin_Code,
              COUNT(Facility_hydroid),
              sum(fac_2020_mgy) AS mgy_2020,
              sum(fac_2040_mgy) AS mgy_2040
              FROM data_minorbasin_raw 
              GROUP BY MinorBasin_Code
              ',sep="")
MB_summary <- sqldf(MB.sql)
###########################################################################
###########################################################################
MB_df <- MinorBasins.csv

st_data <- paste("SELECT *
                  FROM MB_df AS a
                  LEFT OUTER JOIN MB_summary AS b
                  ON (a.code = b.MinorBasin_Code)")  
st_data <- sqldf(st_data)

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
######################################################################################################
#SET UP BASE MAP
base_map <- ggplot(data = MB.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "powderblue",lwd=0.5)+
  geom_polygon(data = state.df, color="gray46", fill = "gray",lwd=0.5)

#ADD LAYER OF INTEREST
map <- base_map + 
  geom_polygon(aes(fill = mgy_2020), color = 'black', size = 0.1, alpha = 0.25) +
  guides(fill=guide_colorbar(title="Legend\n2020 (MGY) By Minor Basin")) +
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

ggsave(plot = map, file = paste0(folder, "state_plan_figures/2020_MinorBasin.png"), width=6.5, height=5)

MB_summary

######################################################################################################
######################################################################################################
# OUTPUT TABLE IN KABLE FORMAT
kable(MB_summary, "latex", booktabs = T,
      caption = paste("Minor Basin",sep=""), 
      label = paste("MinorBasin",sep=""),
      col.names = c("HUC 6 Name",
                    "Minor Basin Name",
                    "Minor Basin Code",
                    "Facility Count",
                    "2020 (MGY)",
                    "2040 (MGY)")) %>%
  kable_styling(bootstrap_options = c("striped", "scale_down")) %>% 
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/MinorBasin_statewide_kable.tex",sep=""))
