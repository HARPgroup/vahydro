library('rgdal') #required for readOGR(), spTransform()
library('rgeos') #required for writeWKT()

###################################################################################################### 
# LOAD FILES
######################################################################################################
#site <- "http://deq2.bse.vt.edu/d.dh/"
site <- "https://deq1.bse.vt.edu/d.dh/"
export_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/vahydro/R/permitting/Salem WTP/"

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
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
#Big Stone Gap WTP extent:
# extent = data.frame(x = c(-82.81, -82.61),
#                     y = c(36.75, 36.95))

#Salem WTP extent:
extent = data.frame(x = c(-80.17, -79.97),
                    y = c(37.19, 37.39))

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

minorbasin <- "OR"

RSeg_layer <- sqldf(paste('SELECT *
                    FROM RSeg_layer AS a
                    WHERE a.hydrocode LIKE "%wshed_',minorbasin,'%"
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
# PROCESS NHDPlus FLOWLINES  
# localpath <- paste(github_location,"/HARParchive/GIS_layers/VWP_projects/",sep="")
# epsg_code <- "4326"
# shp_path <- "BigStoneGap_WTP" 
# shp_layer_name <- "NHDPlus_BigStoneGapWTP_MERGE" 
# shp_layer_load <- readOGR(paste(localpath,shp_path,sep=""),shp_layer_name)
# shp_layer <-spTransform(shp_layer_load, CRS(paste("+init=epsg:",epsg_code,sep=""))) 
# shp_layer_wkt <- writeWKT(shp_layer)
# shp_layer.df <- data.frame(name = "BSG_Flowlines",group = 1,geom = shp_layer_wkt)
# 
# nhdplus_flowlines_sf <- st_as_sf(shp_layer.df, wkt = 'geom')
# nhdplus_flowlines_geom <- geom_sf(data = nhdplus_flowlines_sf,aes(geometry = geom),color = 'dodgerblue3',lwd=0.4, inherit.aes = FALSE)

#---------------------------------------------------------------------------------------------------
# PROCESS INTAKE FEATURE: ROANOKE RIVER 
intake <- om_get_feature(site, hydrocode = 'vwuds_371711080043301', bundle = 'intake', ftype = 'public_water_supply') 
intake_sf <- st_as_sf(intake, wkt = 'geom')
#intake_geom <- geom_sf(data = intake_sf,aes(geometry = geom),color = "black", inherit.aes = FALSE,size=2)
intake_geom <- geom_sf(data = intake_sf,aes(geometry = geom,colour = color_list[2]), inherit.aes = FALSE,size=2)
intake_bbox <- st_bbox(intake_sf)
intake_bbox <- data.frame(x = intake_bbox$xmin, y = intake_bbox$ymin)
intake_point_label <- geom_label_repel(data = intake_bbox, aes(x = x, y = y, group = 1, label = intake$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)

#---------------------------------------------------------------------------------------------------
# PROCESS WELL FEATURE: WELL #1
well_1 <- om_get_feature(site, hydrocode = 'vwuds_371711080044101', bundle = 'well', ftype = 'public_water_supply') 
well_1_sf <- st_as_sf(well_1, wkt = 'geom')
well_1_geom <- geom_sf(data = well_1_sf,aes(geometry = geom),color = "orange", inherit.aes = FALSE,size=1)
well_1_bbox <- st_bbox(well_1_sf)
well_1_bbox <- data.frame(x = well_1_bbox$xmin, y = well_1_bbox$ymin)
well_1_point_label <- geom_label_repel(data = well_1_bbox, aes(x = x, y = y, group = 1, label = well_1$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)

#---------------------------------------------------------------------------------------------------
# PROCESS WELL FEATURE: WELL #2
well_2 <- om_get_feature(site, hydrocode = 'vwuds_371713080044201', bundle = 'well', ftype = 'public_water_supply') 
well_2_sf <- st_as_sf(well_2, wkt = 'geom')
well_2_geom <- geom_sf(data = well_2_sf,aes(geometry = geom),color = "orange", inherit.aes = FALSE,size=1)
well_2_bbox <- st_bbox(well_2_sf)
well_2_bbox <- data.frame(x = well_2_bbox$xmin, y = well_2_bbox$ymin)
well_2_point_label <- geom_label_repel(data = well_2_bbox, aes(x = x, y = y, group = 1, label = well_2$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)

#---------------------------------------------------------------------------------------------------
# PROCESS WELL FEATURE: WELL #3
well_3 <- om_get_feature(site, hydrocode = 'vwuds_371714080043201', bundle = 'well', ftype = 'public_water_supply') 
well_3_sf <- st_as_sf(well_3, wkt = 'geom')
well_3_geom <- geom_sf(data = well_3_sf,aes(geometry = geom),color = "orange", inherit.aes = FALSE,size=1)
well_3_bbox <- st_bbox(well_3_sf)
well_3_bbox <- data.frame(x = well_3_bbox$xmin, y = well_3_bbox$ymin)
well_3_point_label <- geom_label_repel(data = well_3_bbox, aes(x = x, y = y, group = 1, label = well_3$name),size = 2,fill="white",box.padding =1,max.time=3,max.iter=20000)



# #---------------------------------------------------------------------------------------------------
# # PROCESS Big Cherry Reservoir  
# big_cherry_res <- om_get_feature(site, hydrocode = 'nhdplus_22538794', bundle = 'waterbody', ftype = 'nhd_plus') 
# big_cherry_res_sf <- st_as_sf(big_cherry_res, wkt = 'geom')
# big_cherry_res_geom <- geom_sf(data = big_cherry_res_sf,aes(geometry = geom),fill = 'dodgerblue3',color = NA, inherit.aes = FALSE)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS intake point
# intake = data.frame(x = -82.703750, y = 36.833889)
# intake_point <- geom_point(data = intake,aes(x = x, y = y),color="black", fill = NA,lwd=0.5,na.rm=TRUE)
# intake_point_label <- geom_label_repel(data = intake, aes(x = x, y = y, group = 1, label = "Intake"),size = 2,fill="white",box.padding =1)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS WTP Outfall point  
# discharge_wtp = data.frame(x = -82.706311, y = 36.835217)
# discharge_wtp_point <- geom_point(data = discharge_wtp,aes(x = x, y = y),color="black", fill = NA,lwd=0.5,na.rm=TRUE)
# discharge_wtp_point_label <- geom_label_repel(data = discharge_wtp, aes(x = x, y = y, group = 1, label = "WTP Outfall"),size = 2,fill="white",box.padding =1)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS WWTP Outfall point  
# discharge_wwtp = data.frame(x = -82.79966, y = 36.8554)
# discharge_wwtp_point <- geom_point(data = discharge_wwtp,aes(x = x, y = y),color="black", fill = NA,lwd=0.5,na.rm=TRUE)
# discharge_wwtp_point_label <- geom_label_repel(data = discharge_wwtp, aes(x = x, y = y, group = 1, label = "WWTP Outfall"),size = 2,fill="white",box.padding =1)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS dam point  
# dam = data.frame(x = -82.672229, y = 36.846359) 
# dam_point <- geom_point(data = dam,aes(x = x, y = y),color="black", fill = NA,lwd=0.5,na.rm=TRUE)
# dam_point_label <- geom_label_repel(data = dam, aes(x = x, y = y, group = 1, label = "Dam"),size = 2,fill="white",box.padding =1)
# 
# #---------------------------------------------------------------------------------------------------
# # PROCESS weir point  
# weir = data.frame(x = -82.704167, y = 36.834444) 
# weir_point <- geom_point(data = weir,aes(x = x, y = y),color="red", shape = 17, fill = NA,lwd=0.5,na.rm=TRUE)
# # weir_point_label <- geom_label_repel(data = weir, aes(x = x, y = y, group = 1, label = "Monitoring Weir"),size = 2,fill="white",box.padding =1)
# weir_point_label <- geom_label(data = weir, aes(x = x, y = y, group = 1, label = "Monitoring Weir"),size = 2,fill="white",nudge_x = 0.014,nudge_y = 0.004)


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
  
  well_1_geom + well_1_point_label +
  well_2_geom + well_2_point_label +
  well_3_geom + well_3_point_label +
  
  intake_geom + intake_point_label +

  #(0.23, 0.782)

  theme(legend.position = c(1.16, 0.833),
        legend.title=element_text(size=10),
        legend.text=element_text(size=10),
  ) +
  
  # scale_colour_manual(name = c("Legend"),
  #                     values = c("River Segments" = "gray30"),
  #                     guide = guide_legend(override.aes = list(linetype = c("solid"), 
  #                                                              alpha = 1,
  #                                                              shape = c(NA)))) +
    
  scale_colour_manual(name = c("Legend"),
                      values = c("gray30","black"),
                      labels = c("River Segments","Intake"),
                      guide = guide_legend(override.aes = list(linetype = c("solid", "blank"), 
                                                               alpha = c(1,1),
                                                               shape = c(NA,16)))) +
                   
  # scale_fill_manual(values = c("Intake" = "orange"), name = NULL,
  #                   guide = guide_legend(override.aes = list(linetype = "blank", shape = 16))) +
                                            
  ggsn::scalebar(bb.gg, location = 'bottomleft', dist = 2, dist_unit = 'mi',transform = TRUE, model = 'WGS84',
                 st.bottom=FALSE,st.size = 3.5, st.dist = 0.0285,anchor = c(x = extent$x[1]+0.065,y = extent$y[1]+0.002))
  
######################################################################################################
deqlogo <- draw_image(paste(github_location,'/HARParchive/GIS_layers/HiResDEQLogo.tif',sep=''),scale = 0.175, height = 1, x = -.388, y = -0.413) #LEFT BOTTOM LOGO
minorbasin_map <- ggdraw(minorbasin_map)+deqlogo
ggsave(plot = minorbasin_map, file = paste0(export_path,"Salem_WTP_map.png",sep = ""), width=6.5, height=4.95)
######################################################################################################
