library(ggplot2)
library(ggrepel) #advanced map labeling functions
library(rgeos)
library(ggsn)
library(rgdal)
library(dplyr)
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(raster)

#--------------------------------------------------------------------------------------------
#LOAD POLYGON LAYERS
#--------------------------------------------------------------------------------------------
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MB_df <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_minorbasin_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

county_shp <- readOGR("U:/OWS/GIS/VA_Counties", "VA_Counties")

#--------------------------------------------------------------------------------------------

#specify spatial extent for map  
# extent <- data.frame(x = c(-84, -75),
#                      y = c(35, 41))
# #New River Extent
 # extent <- data.frame(x = c(-81.78, -80),
 #                     y = c(36, 37.75))
#Shenandoah Extent
extent <- data.frame(x = c(-77.50, -79.55),
                     y = c(37.7, 39.5))
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
  stateProjected <- sp::SpatialPolygonsDataFrame(state_geom_clip, data.frame('id'), match.ID = TRUE)
  stateProjected@data$id <- as.character(i)
  state.list[[i]] <- stateProjected
}
state <- do.call('rbind', state.list)
state@data <- merge(state@data, STATES, by = 'id')
state@data <- state@data[,-c(2:3)]
state.df <- fortify(state, region = 'id')
state.df <- merge(state.df, state@data, by = 'id')
########################################################################

# MB.sql <- paste('SELECT
#               MinorBasin_Name,
#               MinorBasin_Code,
#               COUNT(Facility_hydroid),
#               sum(mp_2020_mgy) AS mgy_2020,
#               sum(mp_2040_mgy) AS mgy_2040
#               FROM data_minorbasin_raw 
#               GROUP BY MinorBasin_Code
#               ',sep="")
# MB_summary <- sqldf(MB.sql)
###########################################################################

MB_df_sql <- paste('SELECT *
              FROM MB_df 
              WHERE code = "PS" 
              ',sep="")
st_data <- sqldf(MB_df_sql)
# 
# st_data <- paste("SELECT *
#                   FROM MB_df AS a
#                   LEFT OUTER JOIN MB_summary AS b
#                   ON (a.code = b.MinorBasin_Code)")  
# st_data <- sqldf(st_data)
# 
# 
# single_basin_data <- paste('SELECT *
#               FROM st_data 
#               WHERE MinorBasin_Code = "PS" 
#               ',sep="")
# st_data <- sqldf(single_basin_data)

st_data$id <- as.character(row_number(st_data$code))
MB.list <- list()

for (z in 1:length(st_data$code)) {
print(paste("z = ",z,sep=''))
print(st_data$code[z])
  MB_geom <- readWKT(st_data$geom[z])
#print(MB_geom)
  MB_geom_clip <- gIntersection(bb, MB_geom)
  MBProjected <- sp::SpatialPolygonsDataFrame(MB_geom_clip, data.frame('id'), match.ID = TRUE)
  MBProjected@data$id <- as.character(z)
  MB.list[[z]] <- MBProjected
}

MB <- do.call('rbind', MB.list)
MB@data <- merge(MB@data, st_data, by = 'id')
MB@data <- MB@data[,-c(2:3)]
MB.df <- fortify(MB, region = 'id')
MB.df <- merge(MB.df, MB@data, by = 'id')
######################################################################################################
#SUBSET COUNTIES
#manual selection of counties

mb_points <- sqldf("SELECT *
                   FROM data_minorbasin_raw
                   WHERE MinorBasin_Code = 'PS'")

# # #view what fips actually have MPs in them (helps with manual county selection)
# x <- sqldf("SELECT distinct fips_code, fips_name from mb_points")
# x$fips_code
# shen_counties2 <- subset(county_shp, FIPS %in% x$fips_code)

shen_counties <- subset(county_shp, FIPS %in% c(51187,
                                                51165, 
                                                51820,
                                                51015,
                                                51171,
                                                51069,
                                                51139,
                                                51043,   
                                                51660))
s_try <- spTransform(shen_counties, CRS("+proj=longlat +datum=WGS84"))
s_try@data$id = rownames(s_try@data)
s_try.points = fortify(s_try, region="id")
s_try.df = inner_join(s_try.points, s_try@data, by="id")

#select by subsetting with the minor basin boundary
proj4string(MBProjected) <- CRS("+proj=longlat +datum=WGS84")
MBProjected <- spTransform(MBProjected, CRS("+proj=longlat +datum=WGS84"))
c_try <- spTransform(county_shp, CRS("+proj=longlat +datum=WGS84"))
county_subset <- c_try[MBProjected, ]
county_subset@data$id = rownames(county_subset@data)
county_subset.points = fortify(county_subset, region="id")
county_subset.df = inner_join(county_subset.points, county_subset@data, by="id")
names(county_subset.df)

######################################################################################################
#RIVER SEGMENTS
#load in rseg_shp shapefile
rseg_shp <- readOGR(dsn = 'C:/Users/maf95834/Documents/Github/hydro-tools/GIS_LAYERS/VAHydro_Rsegs.gdb', layer = 'VAHydro_RSegs')

#sql subset to minor basin extent
rseg_subset2 <- rseg_shp
rseg_subset2@data$id = rownames(rseg_subset2@data)
rseg_subset2.points = fortify(rseg_subset2, region="id")
rseg_subset2_df = inner_join(rseg_subset2.points, rseg_subset2@data, by="id")
names(rseg_subset2_df)
rseg_subset2_df <- sqldf("SELECT *
                         FROM rseg_subset2_df
                         WHERE code LIKE '%PS%'")

#spatial subset rseg spatialpolygon to minor basin extent
proj4string(rseg_shp) <- CRS("+proj=longlat +datum=WGS84")
rsegProjected <- spTransform(rseg_shp, CRS("+proj=longlat +datum=WGS84"))
rseg_subset <- rsegProjected[MBProjected, ]
plot(rseg_subset)
rseg_subset@data$id = rownames(rseg_subset@data)
rseg_subset.points = fortify(rseg_subset, region="id")
rseg_subset_df = inner_join(rseg_subset.points, rseg_subset@data, by="id")
names(rseg_subset_df)

# #group mb_points by rseg
# mb_points_grouped <- sqldf("SELECT round(sum(mp_2020_mgy)/365.25,2) as MGD_2020, VAHydro_RSeg_Code, VAHydro_RSeg_Name
#                            FROM mb_points
#                            WHERE source_type = 'Groundwater'
#                            AND facility_ftype NOT LIKE '%power'
#                            GROUP BY VAHydro_RSeg_Code")
# #join mb_points dataframe to rseg.df
# rseg_demand_df <- sqldf("SELECT *
#                  FROM rseg_subset_df a
#                  left outer join mb_points_grouped b
#                  ON b.VAHydro_RSeg_Code = a.code")

#--------------------------------7q10-------------------------------#

#load in rseg modeling 7q10 results
rseg_7q10_results <- read.csv(paste(folder,"metrics_watershed_7q10.csv",sep=""))
#join rseg_7q10_results to rseg.df
#percent change is calculated for:
#current 2020-2040 change
#climate change 2020-p10 change
#climate change 2020-p90 change
#exempt change 2020-exempt change
rseg_7q10_df <- sqldf("SELECT *,
    round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2) AS current_pct,
    round(((b.runid_15 - b.runid_11) / b.runid_11) * 100,2) AS cc_p10_pct,
    round(((b.runid_16 - b.runid_11) / b.runid_11) * 100,2) AS cc_p90_pct,
    round(((b.runid_18 - b.runid_11) / b.runid_11) * 100,2) AS exempt_pct
                      FROM rseg_subset_df a
                      LEFT OUTER JOIN rseg_7q10_results b
                      ON a.code = b.hydrocode
                      WHERE a.code LIKE '%PS%'")

#--------------------------------l30-------------------------------#
#load in rseg modeling 7q10 results
rseg_l30_results <- read.csv(paste(folder,"metrics_watershed_l30_Qout.csv",sep=""))
#join rseg_x_results to rseg.df
#percent change is calculated for:
#current 2020-2040 change
#climate change 2020-p10 change
#climate change 2020-p90 change
#exempt change 2020-exempt change
rseg_l30_df <- sqldf("SELECT *,
    round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2) AS current_pct,
    round(((b.runid_15 - b.runid_11) / b.runid_11) * 100,2) AS cc_p10_pct,
    round(((b.runid_16 - b.runid_11) / b.runid_11) * 100,2) AS cc_p90_pct,
    round(((b.runid_18 - b.runid_11) / b.runid_11) * 100,2) AS exempt_pct
                      FROM rseg_subset_df a
                      LEFT OUTER JOIN rseg_l30_results b
                      ON a.code = b.hydrocode
                      WHERE a.code LIKE '%PS%'")
#--------------------------------l90-------------------------------#

rseg_l90_results <- read.csv(paste(folder,"metrics_watershed_l90_Qout.csv",sep=""))
#join rseg_x_results to rseg.df
#percent change is calculated for:
#current 2020-2040 change
#climate change 2020-p10 change
#climate change 2020-p90 change
#exempt change 2020-exempt change
rseg_l30_df <- sqldf("SELECT *,
    round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2) AS current_pct,
    round(((b.runid_15 - b.runid_11) / b.runid_11) * 100,2) AS cc_p10_pct,
    round(((b.runid_16 - b.runid_11) / b.runid_11) * 100,2) AS cc_p90_pct,
    round(((b.runid_18 - b.runid_11) / b.runid_11) * 100,2) AS exempt_pct
                      FROM rseg_subset_df a
                      LEFT OUTER JOIN rseg_l90_results b
                      ON a.code = b.hydrocode
                      WHERE a.code LIKE '%PS%'")
######################################################################################################
#SET UP BASE MAP
base_map <- ggplot(data = MB.df, aes(x = long, y = lat, group = group))+
  geom_polygon(data = bbDF, color="black", fill = "gray",lwd=0.5) +
  geom_polygon(data = state.df, color="gray20", fill = "gray",lwd=0.5)

#ADD LAYER OF INTEREST
map <- base_map + 
  geom_polygon(data = MB.df,fill = "black", color = 'black', size = 1.5, alpha = 0.5) +
  #geom_polygon(data = s_try.df, aes(x = long, y = lat, fill = Name), alpha = .5) +
  ggtitle("Shenandoah Minor Basin") +
  #geom_polygon(data = rseg_subset_df, aes(x = long, y = lat)) +
  #scale_fill_gradient2(low = 'brown', mid = 'white', high = 'blue', labels=function(x) format(x, big.mark = ",", scientific = FALSE)) +
  north(bbDF, location = 'topright', symbol = 12, scale=0.1) +
  ggsn::scalebar(data = bbDF, location = 'bottomright', dist = 25, dist_unit = 'mi', 
           transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
           st.size = 3, st.dist = 0.03,
           anchor = c(
             x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])+0.9,
             y = extent$y[1]+(extent$y[1])*0.001
           ))
ggsave(plot = map, file = paste0(folder, "state_plan_figures/PS_MinorBasin.png"), width=6.5, height=5)

#############################################################################
#rseg outline
map +
  geom_polygon(data = rseg_subset2_df, aes(x = long, y = lat),fill = NA, color='black')
#############################################################################
# #reseg 2020 demand
# map +
#   geom_polygon(data = rseg_demand_df, aes(x = long, y = lat, fill = MGD_2020), color='black') +
#   xlab('Longitude (deg W)') + ylab('Latitude (deg N)') +
#   scale_fill_gradient(
#     limits = c(0,15),
#     labels = seq(0,15,3),
#     breaks = seq(0,15,3),
#     low="chocolate2", high="cornflowerblue", space ="Lab", name = "2020 Demand (MGD)",
#     guide = guide_colourbar(
#       direction = "horizontal",
#       title.position = "top",
#       label.position = "bottom"))
#   
#############################################################################
#rseg 7q10 - current percent change
model_7q10_current_map <- map +
  geom_polygon(data = rseg_7q10_df, aes(x = long, y = lat, fill = current_pct), color='black') +
  scale_fill_gradientn(
    limits = c(-35,35),
    labels = seq(-35,35,10),
    breaks = seq(-35,35,10),
    colors = c("chocolate2","hotpink","cornflowerblue"),
    space ="Lab", name = "20 Year \n % Change",
    guide = guide_colourbar(
      direction = "vertical",
      title.position = "top",
      label.position = "left")) +
  geom_polygon(data = MB.df,fill = NA, color = 'black', size = 1.5) +
  labs(subtitle = "7q10 - Current Model")
ggsave(plot = model_7q10_current_map, file = paste0(folder, "state_plan_figures/PS_model_7q10_current_map.png"), width=6.5, height=7.5)

#----------------------------climate change p10 change-----------------------------------#
#rseg 7q10
model_7q10_cc_p10_map <- map +
  geom_polygon(data = rseg_7q10_df, aes(x = long, y = lat, fill = cc_p10_pct), color='black') +
  scale_fill_gradientn(
    limits = c(-35,35),
    labels = seq(-35,35,10),
    breaks = seq(-35,35,10),
    colors = c("chocolate2","hotpink","cornflowerblue"),
    space ="Lab", name = "20 Year \n % Change",
    guide = guide_colourbar(
      direction = "vertical",
      title.position = "top",
      label.position = "left")) +
  geom_polygon(data = MB.df,fill = NA, color = 'black', size = 1.5) +
  labs(subtitle = "7q10 - Current Model")
ggsave(plot = model_7q10_current_map, file = paste0(folder, "state_plan_figures/PS_model_7q10_current_map.png"), width=6.5, height=7.5)

#----------------------------#climate change 2020-p90 change-----------------------------------#


#----------------------------#exempt change 2020-exempt change-----------------------------------#


###################################### l30##################################
#rseg l30 - current percent change
model_l30_current_map <- map +
  geom_polygon(data = rseg_l30_df, aes(x = long, y = lat, fill = current_pct), color='black') +
  scale_fill_gradientn(
    limits = c(-20,12),
    labels = c('>= 0%','-5 to 0%','-10% to -5%', '-20% to -10%', 'More Than -20%'),
    breaks =  c(-20,-10,-5,0,12),
    colors = c("green","blue","purple","red","red"),
    space ="Lab", name = "20 Year \n % Change",
    guide = guide_colourbar(
      direction = "vertical",
      title.position = "top",
      label.position = "left")) +
  geom_polygon(data = MB.df,fill = NA, color = 'black', size = 1.5) +
  labs(subtitle = "l30 - Current Model")
ggsave(plot = model_l30_current_map, file = paste0(folder, "state_plan_figures/PS_model_l30_current_map.png"), width=6.5, height=7.5)

#----------------------------climate change p10 change-----------------------------------#
up_lim <- max(rseg_l30_df$cc_p10_pct)
low_lim <- min(rseg_l30_df$cc_p10_pct)
model_l30_p10_map <- map +
  geom_polygon(data = rseg_l30_df, aes(x = long, y = lat, fill = cc_p10_pct), color='black') +
  scale_fill_gradientn(
    limits = c(low_lim,up_lim),
    labels = c( 'More Than -20%','-20%','-10%','-5%','>= 0%',''),
    breaks =  c(low_lim,-20,-10,-5,0,up_lim),
    colors = c("orangered4","chocolate2","goldenrod1","slateblue4","slateblue4"),
    space ="Lab", name = " 2020 to 90th Percentile \n % Change",
    guide = guide_colourbar(
      direction = "vertical",
      title.position = "top",
      label.position = "left")) +
  geom_polygon(data = MB.df,fill = NA, color = 'black', size = 1.5) +
  labs(subtitle = "l30 - Climate Change Dry Model")
ggsave(plot = model_l30_p10_map, file = paste0(folder, "state_plan_figures/PS_model_l30_p10_map.png"), width=6.5, height=7.5)

str(rseg_l30_df)
library(RColorBrewer)
display.brewer.pal(name = 'Dark2', n = 5)
#----------------------------#climate change p90 change-----------------------------------#

#----------------------------#exempt change 2020-exempt change-----------------------------------#

###################################### l90##################################
#rseg l90 - current percent change


#----------------------------climate change p10 change-----------------------------------#

#----------------------------#climate change p90 change-----------------------------------#

#----------------------------#exempt change 2020-exempt change-----------------------------------#

#############################################################################
#All points in minor basin 

map + geom_point(data=mb_points, aes(x=corrected_longitude, y=corrected_latitude, size=mp_2040_mgy, fill=mp_2040_mgy, group = NULL), shape=21, alpha=0.8) 

#############################################################################
#all points in minor basin (specific facility, no ssu)

specific_fac_sql <- paste('SELECT facility_name, system_type, MP_bundle,
               ',aggregate_select,',fips_name, corrected_latitude, corrected_longitude
               FROM mb_points
               WHERE wsp_ftype NOT LIKE "%ssusm"
               GROUP BY Facility_hydroid', sep="")

specific_fac_points <- sqldf(specific_fac_sql)


specific_fac_map <- map + geom_point(data=specific_fac_points, aes(x=corrected_longitude, y=corrected_latitude, size=MGD_2040, fill=MGD_2040, group = NULL), alpha=0.8) +
  labs(subtitle = "2040 Demand - Facility Locations") +
  # scale_shape_manual(values=c(21, 24), name = "Source Type", labels = c("Surface Water","Groundwater"),
  #                    guide = guide_legend(
  #                      direction = "horizontal",
  #                      title.position = "top",ncol = 2,
  #                      label.position = "bottom",
  #                      title.hjust = 0.5)) +
  scale_fill_gradient(
    limits = c(0,10),
    labels = seq(0,10,2),
    breaks = seq(0,10,2),
    low="green2", high="orange", space ="Lab", name = "2040 Demand (MGD)",
    guide = guide_colourbar(
      direction = "horizontal",
      title.position = "top",
      label.position = "bottom")) +
  #geom_text(data = top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),hjust=0, vjust=0, size = 2) 
  # geom_label_repel(data = top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=label_names, group = NULL,color = MP_bundle),
  #                  box.padding   = 0.2, 
  #                  point.padding = 0.3,label.padding = .12,
  #                  segment.color = 'grey50', size = 3) +
  guides(color = FALSE, size = FALSE)+
  theme(legend.position = "bottom",
        legend.box = "horizontal")
ggsave(plot = specific_fac_map, file = paste0(folder, "state_plan_figures/PS_2040_MinorBasin_specific_fac_map.png"), width=6.5, height=7.5)

#############################################################################

  #only county-wide estimates (ssu aka diffuse county demand)
  map + geom_point(data=ssu_points, aes(x=corrected_longitude, y=corrected_latitude, size=mp_2040_mgy, fill=mp_2040_mgy, group = NULL), shape=21, alpha=0.8) 
#############################################################################
  #TOP 5
  
  top_5_gw_sql <- paste('SELECT facility_name, system_type, MP_bundle,
               ',aggregate_select,',fips_name, corrected_latitude, corrected_longitude
               FROM mb_points
               WHERE MP_bundle = "well"
               AND wsp_ftype NOT LIKE "%ssusm"
               GROUP BY Facility_hydroid
               ORDER BY MGD_2040 DESC
               LIMIT 5', sep="")
  
  gw_top5_points <- sqldf(top_5_gw_sql)
  
  top_5_sw_sql <- paste('SELECT facility_name, system_type, MP_bundle,
               ',aggregate_select,',fips_name, corrected_latitude, corrected_longitude
               FROM mb_points
               WHERE MP_bundle = "intake"
               AND wsp_ftype NOT LIKE "%ssusm"
               GROUP BY Facility_hydroid
               ORDER BY MGD_2040 DESC
               LIMIT 5', sep="")
  
  sw_top5_points <- sqldf(top_5_sw_sql)
#######################################  
#   #top 5 GW
# top5_map <- map + geom_point(data=gw_top5_points, aes(x=corrected_longitude, y=corrected_latitude, size=MGD_2040, fill=MGD_2040, group = NULL), shape=21, alpha=0.8) +
#  # geom_text(data = gw_top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),hjust=0, vjust=0, size = 2) 
#   geom_label_repel(data = gw_top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),
#                    color = 'darkorange',
#                    box.padding   = 0.2, 
#                    point.padding = 0.5,label.padding = .12,
#                    segment.color = 'grey50', size = 2) +
#   #top 5 SW
#   geom_point(data=sw_top5_points, aes(x=corrected_longitude, y=corrected_latitude, size=MGD_2040, fill=MGD_2040, group = NULL), shape=23, alpha=0.8) +   
#     # geom_text(data = gw_top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),hjust=0, vjust=0, size = 2) 
#     geom_label_repel(data = sw_top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),
#                      color = 'darkgreen',
#                      box.padding   = 0.2, 
#                      point.padding = 0.5,label.padding = .12,
#                      segment.color = 'grey50', size = 2) 
# ggsave(plot = top5_map, file = paste0(folder, "state_plan_figures/PS_2020_MinorBasin_top5_map.png"), width=6.5, height=5)
  
#######################################

#RBIND INTO 1 TOP5 table 
top5_points <- rbind(gw_top5_points, sw_top5_points) 
top5_points$label_names <- c('A','B','C','D','E','A','B','C','D','E')

#top 5 GW
top5_map <- map + geom_point(data=top5_points, aes(x=corrected_longitude, y=corrected_latitude, size=MGD_2040, fill=MGD_2040, group = NULL, shape= MP_bundle) , size = 4.5) +
  labs(subtitle = "2040 Demand - Top 5 Users") +
  scale_shape_manual(values=c(22, 24), name = "Source Type", labels = c("Surface Water","Groundwater"),
      guide = guide_legend(
      direction = "horizontal",
      title.position = "top",ncol = 2,
      label.position = "bottom",
      title.hjust = 0.5)) +
  scale_fill_gradient(
    limits = c(0,10),
    labels = seq(0,10,2),
    breaks = seq(0,10,2),
    low="green2", high="orange", space ="Lab", name = "2040 Demand (MGD)",
    guide = guide_colourbar(
      direction = "horizontal",
      title.position = "top",
      label.position = "bottom")) +
  #geom_text(data = top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=facility_name, group = NULL),hjust=0, vjust=0, size = 2) 
  geom_label_repel(data = top5_points,aes(x=corrected_longitude, y=corrected_latitude, label=label_names, group = NULL,color = MP_bundle),
                   box.padding   = 0.2, 
                   point.padding = 0.3,label.padding = .12,
                   segment.color = 'grey50', size = 3) +
  guides(color = FALSE)+
  theme(legend.position = "bottom",
        legend.box = "horizontal")
ggsave(plot = top5_map, file = paste0(folder, "state_plan_figures/PS_2040_MinorBasin_top5_map.png"), width=6.5, height=7.5)

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
