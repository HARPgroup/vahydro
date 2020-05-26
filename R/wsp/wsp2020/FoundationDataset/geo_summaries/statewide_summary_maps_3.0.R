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
library(httr)
######################################################################################################
### LOAD LAYERS  #####################################################################################
######################################################################################################
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)
river_shp <- readOGR(paste(hydro_tools_location,'/GIS_LAYERS/MajorRivers',sep = ''), "MajorRivers")
#RSeg.csv <- read.table(file = paste(hydro_tools_location,'/GIS_LAYERS/VAHydro_RSegs.csv', sep = ''), sep = ',', header = TRUE)
#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
  localpath <- tempdir()
  filename <- paste("vahydro_riversegs_export.csv",sep="")
  destfile <- paste(localpath,filename,sep="\\")
  download.file(paste("http://deq2.bse.vt.edu/d.dh/vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
  RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")

######################################################################################################
###      USER INPUTS      ############################################################################
######################################################################################################

#Metric options include "7q10", "l30_Qout", "l90_Qout","l30_cc_Qout","l90_cc_Qout"
metric <- "l30_cc_Qout"
runid_a <- "runid_11"
runid_b <- "runid_19"

#selects plot title based on chosen metric
metric_title <- case_when(metric == "l30_Qout" ~ "30 Day Low Flow",
                          metric == "l90_Qout" ~ "90 Day Low Flow",
                          metric == "7q10" ~ "7Q10",
                          metric == "l30_cc_Qout" ~ "30 Day Low Flow",
                          metric == "l90_cc_Qout" ~ "90 Day Low Flow")

#selects plot title based on chosen scenarios
scenario_a_title <- case_when(runid_a == "runid_11" ~ "2020",
                              runid_a == "runid_12" ~ "2030",
                              runid_a == "runid_13" ~ "2040")
scenario_b_title <- case_when(runid_b == "runid_12" ~ "2030",
                              runid_b == "runid_13" ~ "2040",
                              runid_b == "runid_14" ~ "Median Climate Change Scenario",
                              runid_b == "runid_15" ~ "Dry Climate Change Scenario",
                              runid_b == "runid_16" ~ "Wet Climate Change Scenario",
                              runid_b == "runid_17" ~ "Dry Climate Change Scenario",
                              runid_b == "runid_18" ~ "Exempt Users",
                              runid_b == "runid_19" ~ "Median Climate Change Scenario",
                              runid_b == "runid_20" ~ "Wet Climate Change Scenario")

plot_title <- paste("Percent Change in ",metric_title," \n     (",scenario_a_title," to ",scenario_b_title,")",sep="")

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
### PROCESS VIRGINIA STATE LAYER  ############################################################################

va_state <- STATES[STATES$state == 'VA',]
va_state_sf <- st_as_sf(va_state, wkt = 'geom')

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
### PROCESS Major Rivers LAYER  #######################################################################
######################################################################################################
# proj4string(bbProjected) <- CRS("+proj=longlat +datum=WGS84")
# bbProjected <- spTransform(bbProjected, CRS("+proj=longlat +datum=WGS84"))
# river_shpProjected <- spTransform(river_shp, CRS("+proj=longlat +datum=WGS84"))
# river_clip <- gIntersection(bbProjected,river_shpProjected)
# river.df <- sp::SpatialLinesDataFrame(river_clip, data.frame('id'), match.ID = TRUE)
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
RSeg_data <- RSeg_data[,-10] #need to remove duplicate hydrocode column? 
# REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING)
RSeg_valid_geoms <- paste("SELECT *
                  FROM RSeg_data
                  WHERE geom != ''")  
RSeg_data <- sqldf(RSeg_valid_geoms)
length(RSeg_data[,1])

#USED FOR PLOTTING THE TIDAL SEGMENTS LAYER
RSeg_data_base <- RSeg_data

#EXCLUDE TIDAL SEGMENTS FROM MAP
RSeg_Tidal <- paste('SELECT *
                  FROM RSeg_data
                  WHERE hydrocode NOT LIKE "vahydrosw_wshed_PL%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_RL%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_YM%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_YL%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_YP%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_JB%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_MN%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_ES%0000"
                  AND hydrocode NOT LIKE "vahydrosw_wshed_EL%0000"
                   ',sep = '')
# #EXCLUDE TIDAL SEGMENTS FROM MAP
# RSeg_Tidal <- paste('SELECT *
#                   FROM RSeg_data
#                   WHERE hydrocode NOT LIKE "vahydrosw_wshed_RL%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_YM%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_YL%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_YP%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_JB%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_MN%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_ES%0000"
#                   AND hydrocode NOT LIKE "vahydrosw_wshed_EL%0000"
#                    ',sep = '')  
RSeg_data <- sqldf(RSeg_Tidal)
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
RSeg_sf <- st_as_sf(RSeg_data, wkt = 'geom')
RSeg_base_sf <- st_as_sf(RSeg_data_base, wkt = 'geom')

### PROCESS Southern Rivers basins (no Climate Change model runs) LAYER  #######################################################################
if (runid_b  %in% c('runid_14','runid_15','runid_16','runid_17','runid_19','runid_20')) {
  #subset
  RSeg_southern_basins <- sqldf("SELECT * 
                                FROM RSeg_data_base
                                WHERE hydrocode LIKE 'vahydrosw_wshed_BS%'
                                OR hydrocode LIKE 'vahydrosw_wshed_TU%'
                                OR hydrocode LIKE 'vahydrosw_wshed_NR%'
                                OR hydrocode LIKE 'vahydrosw_wshed_OR%'
                                OR hydrocode LIKE 'vahydrosw_wshed_OD%'
                                OR hydrocode LIKE 'vahydrosw_wshed_MN%'
                                OR hydrocode LIKE 'vahydrosw_wshed_KU0_8980_0000'
                                ")
  #convert to spatial object
  RSeg_southern_basins_sf <- st_as_sf(RSeg_southern_basins, wkt = 'geom')
  #geom_sf to plot object
  RSeg_southern_b_geom <- geom_sf(data = RSeg_southern_basins_sf,aes(geometry = geom),fill = 'gray30',color = 'gray30', inherit.aes = FALSE)
  #annotation rectangle + text
  #cc_models_box <- annotate("rect", xmin = extent$x[1]+2.5, xmax = extent$x[1]+5.3, ymin = extent$y[1]+1.75, ymax = extent$y[1]+2.03, color = 'black', fill = 'gray30', lwd = .4 )
  cc_models_box <- annotate("rect", xmin = extent$x[1]+ 3.05, xmax = extent$x[1]+4.8, ymin = extent$y[1]+1.68, ymax = extent$y[1]+2.1, color = 'black', fill = 'gray30', lwd = .4 )
  #annotate text
  #cc_models_text <- annotate("text", x = extent$x[1]+3.9, y = extent$y[1]+1.9, label = "Climate Models to be Developed", size = 3, color = 'snow')
  cc_models_text <- annotate("text", x = extent$x[1]+3.9, y = extent$y[1]+1.9, label = "Climate Models to be \n developed prior to 2023", size = 2.5, color = 'snow')
  
} else {
  RSeg_southern_b_geom <- geom_blank()
  cc_models_box <- geom_blank()
  cc_models_text <- geom_blank()
}

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
###no Tidal segments
  #option A
  #geom_sf(data = RSeg_sf,aes(geometry = geom,fill = 'aliceblue',alpha = .15), lwd = .3, inherit.aes = FALSE,  show.legend=FALSE)
###include Tidal segments
  #option B
  #geom_sf(data = RSeg_base_sf,aes(geometry = geom,fill = 'aliceblue'), lwd = .3, inherit.aes = FALSE,  show.legend=FALSE)
  #option c
  geom_sf(data = RSeg_base_sf,aes(geometry = geom,fill = 'aliceblue',alpha = .15), lwd = .3, inherit.aes = FALSE,  show.legend=FALSE)


#colnames(RSeg_data)
map <- base_map + 
  geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'antiquewhite1'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'antiquewhite2'), inherit.aes = FALSE)+ 
  geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'antiquewhite3'), inherit.aes = FALSE)+ 
  geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'antiquewhite4'), inherit.aes = FALSE)+ 
  RSeg_southern_b_geom+
  scale_fill_manual(values=c("gray55","darkolivegreen3","cornflowerblue","khaki2","plum3","coral3"), 
                    name = "Legend",
                    labels = c("Tidal Segment",
                               ">= 0%", 
                               "-5% to 0%", 
                               "-10% to -5%", 
                               "-20% to -10%", 
                               "More than -20%"))+
  guides(fill = guide_legend(reverse=TRUE))+
  geom_polygon(data = MB.df, color="gray20", fill = NA,lwd=0.7)+
  
  draw_image(paste(folder,'tables_maps/HiResDEQLogo.tif',sep=''),scale = 2, height = 1, x = extent$x[1]+0.56, y = extent$y[1])+ 
  cc_models_box+
  cc_models_text+
  
  # ADD BORDER ####################################################################
  geom_polygon(data = bbDF, color="black", fill = NA,lwd=0.5)+
  
  ggtitle(paste("     ",plot_title,sep=""))+
  theme(legend.justification=c(0,1), 
        legend.position=c(0.051,0.945)) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        panel.border = element_blank())+
geom_sf(data = va_state_sf, aes(geometry = geom), fill = NA, color="snow", lwd = .6, inherit.aes = FALSE)

#map <- map + geom_line(data = river.df,aes(x=long,y=lat, group=group), inherit.aes = FALSE,  show.legend=FALSE, color = 'royalblue4', size = .5)

ggsave(plot = map, file = paste0(export_path, "tables_maps/statewide/chg_",runid_a,"_to_",runid_b,"_",metric,"_map.png"), width=6.5, height=5)
