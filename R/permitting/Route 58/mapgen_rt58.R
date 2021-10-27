library('rgdal') #required for readOGR(), spTransform()
library('rgeos') #required for writeWKT()

###################################################################################################### 
# LOAD FILES
######################################################################################################
#site <- "http://deq2.bse.vt.edu/d.dh/"
site <- "https://deq1.bse.vt.edu/d.dh/"

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
export_path <- paste(github_location,"/vahydro/R/permitting/Route 58/",sep="")
source(paste(hydro_tools,"GIS_functions/base.layers.R",sep = '/'))
source(paste(hydro_tools,"GIS_functions/base.map.R",sep = '/'))
if(!exists("baselayers")) {baselayers <- load_MapLayers(site = site)} #Load map layers if they're not already loaded in the RStudio environment

#GET REST TOKEN
rest_uname = FALSE
rest_pw = FALSE
source(paste("/var/www/R/auth.private", sep = "\\"))
source(paste(hydro_tools,"VAHydro-2.0","rest_functions.R", sep = "\\")) 
token <- rest_token(site, token, rest_uname, rest_pw)

######################################################################################################
### BASEMAP OBJECT
######################################################################################################
lat <- 36.676647
lon <- -80.277261
#scaler <- 0.125
#scaler <- 0.1
#scaler <- 0.08 #GOOD SCALER
scaler <- 0.06

extent = data.frame(x = c(lon-scaler, lon+scaler),
                    y = c(lat-scaler, lat+scaler))

baselayers.gg <- base.layers(baselayers,extent=extent)
basemap.obj <- base.map(baselayers.gg,extent=extent,
                        plot_margin = c(0.16,0.2,0.16,-3.9), #top, right, bottom, left
                        plot_zoom = 13,
                        scale_bar = FALSE)
#ggsave(plot = basemap.obj, file = paste0(export_path, "tables_maps/Xfigures/","salem_basemap.png",sep = ""), width=6.5, height=4.95)

######################################################################################################
### LOAD MAP LAYERS
######################################################################################################
#---------------------------------------------------------------------------------------------------
color_list <- sort(colors())

# PROCESS RSegs
RSeg.csv <- baselayers[[which(names(baselayers) == "RSeg.csv")]]
RSeg_valid_geoms <- paste("SELECT * FROM 'RSeg.csv'WHERE geom != ''") # REMOVE ANY WITH EMPTY GEOMETRY FIELD (NEEDED PRIOR TO GEOPROCESSING) 
RSeg_layer <- sqldf(RSeg_valid_geoms)

minorbasin <- "OD"

RSeg_layer <- sqldf(paste('SELECT *
                    FROM RSeg_layer AS a
                    WHERE a.hydrocode LIKE "%',minorbasin,'%"
  		              ORDER BY hydroid ASC
  		              ',sep = ''))

RSeg_layer_sf <- st_as_sf(RSeg_layer, wkt = 'geom')
RSeg_layer_geom <- geom_sf(data = RSeg_layer_sf,aes(geometry = geom,colour = color_list[1]),
                           lwd=2,alpha=0, inherit.aes = FALSE, 
                           show.legend = "line")

# RSeg_layer_geom <- geom_sf(data = RSeg_layer_sf,aes(geometry = geom,colour = "River Segments"),
#                            lwd=2,alpha=0.25, inherit.aes = FALSE, 
#                            show.legend = "line")

#---------------------------------------------------------------------------------------------------
#PROCESS NHDPlus FLOWLINES
localpath <- paste(github_location,"/HARParchive/GIS_layers/VWP_projects/",sep="")
epsg_code <- "4326"
shp_path <- "Route_58"
shp_layer_name <- "NHDPlus_Rt58"
shp_layer_load <- readOGR(paste(localpath,shp_path,sep=""),shp_layer_name)
shp_layer <-spTransform(shp_layer_load, CRS(paste("+init=epsg:",epsg_code,sep="")))
shp_layer_wkt <- writeWKT(shp_layer)
shp_layer.df <- data.frame(name = "NHDPlus_Flowlines",group = 1,geom = shp_layer_wkt)

nhdplus_flowlines_sf <- st_as_sf(shp_layer.df, wkt = 'geom')
nhdplus_flowlines_geom <- geom_sf(data = nhdplus_flowlines_sf,aes(geometry = geom),color = "dodgerblue3",
                                  lwd=0.75, inherit.aes = FALSE)

#---------------------------------------------------------------------------------------------------
# PROCESS INTAKE FEATURE 1
intake_1 <- om_get_feature(site, hydrocode = 'intake_1_bull_mountain_fork', bundle = 'intake', ftype = 'other') 
intake_1_sf <- st_as_sf(intake_1, wkt = 'geom')
intake_1_geom <- geom_sf(data = intake_1_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=2)
intake_1_bbox <- st_bbox(intake_1_sf)
intake_1_bbox <- data.frame(x = intake_1_bbox$xmin, y = intake_1_bbox$ymin)
intake_1_label <- geom_label_repel(data = intake_1_bbox, aes(x = x, y = y, group = 1, label = intake_1$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
#---------------------------------------------------------------------------------------------------
# PROCESS INTAKE FEATURE 2
intake_2 <- om_get_feature(site, hydrocode = 'well_2_ut_north_fork_poorhouse_creek', bundle = 'intake', ftype = 'other') 
intake_2_sf <- st_as_sf(intake_2, wkt = 'geom')
intake_2_geom <- geom_sf(data = intake_2_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=2)
intake_2_bbox <- st_bbox(intake_2_sf)
intake_2_bbox <- data.frame(x = intake_2_bbox$xmin, y = intake_2_bbox$ymin)
intake_2_label <- geom_label_repel(data = intake_2_bbox, aes(x = x, y = y, group = 2, label = intake_2$name),size = 2,fill="white",box.padding =2,max.time=3,max.iter=20000)
#---------------------------------------------------------------------------------------------------
# PROCESS INTAKE FEATURE 3
intake_3 <- om_get_feature(site, hydrocode = 'intake_3_north_fork_poorhouse_creek', bundle = 'intake', ftype = 'other') 
intake_3_sf <- st_as_sf(intake_3, wkt = 'geom')
intake_3_geom <- geom_sf(data = intake_3_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=2)
intake_3_bbox <- st_bbox(intake_3_sf)
intake_3_bbox <- data.frame(x = intake_3_bbox$xmin, y = intake_3_bbox$ymin)
intake_3_label <- geom_label_repel(data = intake_3_bbox, aes(x = x, y = y, group = 3, label = intake_3$name),size = 2,fill="white",box.padding =3,max.time=3,max.iter=20000)





# #---------------------------------------------------------------------------------------------------
# # PROCESS WELL FEATURE: WELL #1
# well_1 <- om_get_feature(site, hydrocode = 'vwuds_371711080044101', bundle = 'well', ftype = 'public_water_supply') 
# well_1_sf <- st_as_sf(well_1, wkt = 'geom')
# well_1_geom <- geom_sf(data = well_1_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=1)
# well_1_bbox <- st_bbox(well_1_sf)
# well_1_bbox <- data.frame(x = well_1_bbox$xmin, y = well_1_bbox$ymin)
# well_1_point_label <- geom_label_repel(data = well_1_bbox, aes(x = x, y = y, group = 1, label = well_1$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS WELL FEATURE: WELL #2
# well_2 <- om_get_feature(site, hydrocode = 'vwuds_371713080044201', bundle = 'well', ftype = 'public_water_supply') 
# well_2_sf <- st_as_sf(well_2, wkt = 'geom')
# well_2_geom <- geom_sf(data = well_2_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=1)
# well_2_bbox <- st_bbox(well_2_sf)
# well_2_bbox <- data.frame(x = well_2_bbox$xmin, y = well_2_bbox$ymin)
# well_2_point_label <- geom_label_repel(data = well_2_bbox, aes(x = x, y = y, group = 1, label = well_2$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS WELL FEATURE: WELL #3
# well_3 <- om_get_feature(site, hydrocode = 'vwuds_371714080043201', bundle = 'well', ftype = 'public_water_supply') 
# well_3_sf <- st_as_sf(well_3, wkt = 'geom')
# well_3_geom <- geom_sf(data = well_3_sf,aes(geometry = geom,colour = color_list[3]), inherit.aes = FALSE,size=1)
# well_3_bbox <- st_bbox(well_3_sf)
# well_3_bbox <- data.frame(x = well_3_bbox$xmin, y = well_3_bbox$ymin)
# well_3_point_label <- geom_label_repel(data = well_3_bbox, aes(x = x, y = y, group = 1, label = well_3$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS Converyance FEATURE: Salem WTP TO SALEM SERVICE AREA
# transfer <- om_get_feature(site, hydrocode = 'vwuds_conv-0739-0736', bundle = 'conveyance', ftype = 'water_transfer') 
# transfer_sf <- st_as_sf(transfer, wkt = 'geom')
# transfer_geom <- geom_sf(data = transfer_sf,aes(geometry = geom,colour = color_list[4]),lty=3, inherit.aes = FALSE,size=0.75)
# transfer_bbox <- st_bbox(transfer_sf)
# transfer_bbox <- data.frame(x = transfer_bbox$xmin, y = transfer_bbox$ymin)
# transfer_point_label <- geom_label_repel(data = transfer_bbox, aes(x = x, y = y, group = 1, label = transfer$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS GAGE FEATURE: USGS Gage 02055000
# usgs_02055000 <- om_get_feature(site, hydrocode = 'usgs_02055000', bundle = 'usgsgage', ftype = 'flowgage') 
# usgs_02055000_sf <- st_as_sf(usgs_02055000, wkt = 'geom')
# usgs_02055000_geom <- geom_sf(data = usgs_02055000_sf,aes(geometry = geom,colour = color_list[5]), inherit.aes = FALSE,size=2,pch=17)
# usgs_02055000_bbox <- st_bbox(usgs_02055000_sf)
# usgs_02055000_bbox <- data.frame(x = usgs_02055000_bbox$xmin, y = usgs_02055000_bbox$ymin)
# usgs_02055000_point_label <- geom_label_repel(data = usgs_02055000_bbox, aes(x = x, y = y, group = 1, label = usgs_02055000$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS GAGE FEATURE: USGS Gage 02054530
# usgs_02054530 <- om_get_feature(site, hydrocode = 'usgs_02054530', bundle = 'usgsgage', ftype = 'flowgage') 
# usgs_02054530_sf <- st_as_sf(usgs_02054530, wkt = 'geom')
# usgs_02054530_geom <- geom_sf(data = usgs_02054530_sf,aes(geometry = geom,colour = color_list[5]), inherit.aes = FALSE,size=2,pch=17)
# usgs_02054530_bbox <- st_bbox(usgs_02054530_sf)
# usgs_02054530_bbox <- data.frame(x = usgs_02054530_bbox$xmin, y = usgs_02054530_bbox$ymin)
# usgs_02054530_point_label <- geom_label_repel(data = usgs_02054530_bbox, aes(x = x, y = y, group = 1, label = usgs_02054530$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)




# #---------------------------------------------------------------------------------------------------
# # PROCESS Big Cherry Reservoir  
# big_cherry_res <- om_get_feature(site, hydrocode = 'nhdplus_22538794', bundle = 'waterbody', ftype = 'nhd_plus') 
# big_cherry_res_sf <- st_as_sf(big_cherry_res, wkt = 'geom')
# big_cherry_res_geom <- geom_sf(data = big_cherry_res_sf,aes(geometry = geom),fill = 'dodgerblue3',color = NA, inherit.aes = FALSE)
# 

#---------------------------------------------------------------------------------------------------
# PROCESS minor basins layer 
mb.gg <- baselayers.gg[[which(names(baselayers.gg) == "mb.gg")]]
minorbasin_layer <- geom_polygon(data = mb.gg,aes(x = long, y = lat, group = group),color="black", fill = NA,lwd=1,na.rm=TRUE)

# LOAD bounding box (needed for scalebar)
bb.gg <- baselayers.gg[[which(names(baselayers.gg) == "bb.gg")]]

###################################################################################################### 
# ADD MAP LAYERS TO BASEMAP OBJECT
######################################################################################################
minorbasin_map <- basemap.obj + 
  minorbasin_layer + 
  RSeg_layer_geom + 
  nhdplus_flowlines_geom +
  # well_1_geom + 
  # #well_1_point_label +
  # well_2_geom + 
  # #well_2_point_label +
  # well_3_geom + 
  # #well_3_point_label +
  intake_1_geom + intake_1_label +
  intake_2_geom + intake_2_label +
  intake_3_geom + intake_3_label +
  # transfer_geom + 
  # #transfer_point_label +
  # usgs_02055000_geom + usgs_02055000_point_label +
  # usgs_02054530_geom + usgs_02054530_point_label +
  
  theme(legend.position = c(1.16, 0.833),
        legend.title=element_text(size=10),
        legend.text=element_text(size=10)) +

  # scale_colour_manual(name = c("Legend"),
  #                     values = c("gray30","dodgerblue3","black"),
  #                     labels = c("River Segments","NHDPlus","Intake"),
  #                     guide = guide_legend(override.aes = list(linetype = c("solid","solid","blank"), 
  #                                                              alpha = c(1,1,1),
  #                                                              shape = c(NA,NA,16)))) +
  scale_colour_manual(name = c("Legend"),
                      values = c("gray30","black"),
                      labels = c("River Segments","Intake"),
                      guide = guide_legend(override.aes = list(linetype = c("solid","blank"), 
                                                               alpha = c(1,1),
                                                               shape = c(NA,16)))) +
                                            
  ggsn::scalebar(bb.gg, location = 'bottomleft', dist = 1, dist_unit = 'mi',transform = TRUE, model = 'WGS84',
                 st.bottom=FALSE,st.size = 3.5, st.dist = 0.0285,anchor = c(x = extent$x[1]+0.045,y = extent$y[1]+0.002))
  
######################################################################################################
deqlogo <- draw_image(paste(github_location,'/HARParchive/GIS_layers/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1, x = -.388, y = -0.413) #LEFT BOTTOM LOGO
minorbasin_map <- ggdraw(minorbasin_map)+deqlogo
ggsave(plot = minorbasin_map, file = paste0(export_path,"Rt58_map.png",sep = ""), width=6.5, height=4.95)
######################################################################################################
