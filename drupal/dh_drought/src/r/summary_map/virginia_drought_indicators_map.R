###################################################################################################### 
# LOAD FILES
######################################################################################################
library("dataRetrieval")
library("sqldf")
library("png")
library("grid")
library("patchwork")
color_list <- sort(colors())
options(scipen=9999)

site <- "http://deq1.bse.vt.edu/d.dh/"
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
# 
# dependencies <- "C:/Users/nrf46657/Desktop/DMTF/web_map/drought_map_dependencies/"
dependencies <- paste0(github_location,"/vahydro/drupal/dh_drought/src/r/summary_map/drought_map_dependencies/")
# export_path <- paste0("C:/Users/nrf46657/Desktop/DMTF/web_map/")
# export_path <-"/var/www/html/drought/state/images/maps"
source(paste(dependencies,"base.layers.R",sep = '/'))
source(paste(dependencies,"base.map.R",sep = '/'))
#Load map layers if they're not already
if(!exists("baselayers")) {baselayers <- load_MapLayers(site = site)} 
###################################################################################################### 
# GENERATE MAP
######################################################################################################

# BASEMAP ############################################################################################
baselayers.gg <- base.layers(baselayers)
basemap.obj <- base.map(baselayers.gg)

# LOAD FIPS LAYER
fips_csv <- baselayers[[which(names(baselayers) == "fips.csv")]]
fips_df <-sqldf(paste('SELECT *,fips_geom AS geom,
                          CASE
                            WHEN fips_code IN (51191,51167,51169,51173,51520,51185,51720,51105,51027,51051,51195) THEN "',color_list[1],'"
                            WHEN fips_code IN (51025,51081,51053,51620,51111,51135,51149,51175,51181,51183,51595) THEN "',color_list[2],'"
                            WHEN fips_code IN (51131,51001) THEN "',color_list[3],'"
                            WHEN fips_code IN (51049,51075,51085,51087,51009,51570,51125,51145,51147,51041,51670,51680,51730,51760,51007,51065,51003,51011,51029,51540) THEN "',color_list[4],'"
                            WHEN fips_code IN (51021,51197,51035,51063,51071,51121,51155,51640,51077,51750) THEN "',color_list[5],'"
                            WHEN fips_code IN (51057,51073,51099,51103,51097,51101,51133,51159,51115,51119,51033,51193) THEN "',color_list[6],'"
                            WHEN fips_code IN (51047,51109,51113,51137,51157,51177,51179,51630,51079) THEN "',color_list[7],'"
                            WHEN fips_code IN (51013,51059,51061,51610,51153,51600,51107,51683,51685,51510) THEN "',color_list[8],'"
                            WHEN fips_code IN (51031,51037,51067,51083,51590,51089,51161,51690,51019,51770,51775,51143,51117,51515,51141) THEN "',color_list[9],'"
                            WHEN fips_code IN (51820,51840,51171,51015,51043,51165,51660,51187,51790,51139,51069) THEN "',color_list[10],'"
                            WHEN fips_code IN (51093,51550,51800,51810,51710,51740) THEN "',color_list[11],'"
                            WHEN fips_code IN (51045,51163,51678,51530,51005,51091,51580,51023,51017) THEN "',color_list[12],'"
                            WHEN fips_code IN (51830,51036,51095,51127,51650,51199,51735,51700) THEN "',color_list[13],'"
                            ELSE "white"
                          END AS col
                        FROM fips_csv 
                        WHERE fips_code NOT LIKE "3%"',sep="")) #EXCLUDE NC LOCALITIES
fips.sf <- st_as_sf(fips_df, wkt = 'geom')
# fips.gg <- geom_sf(data = fips.sf,aes(fill = factor(col)),lwd=0.4, col = "black", alpha = 0.5, inherit.aes = FALSE, show.legend =TRUE)

# LOAD RIVERS LAYER
rivs.gg <- baselayers.gg[[which(names(baselayers.gg) == "rivs.gg")]]
rivs.gg <- geom_path(data = rivs.gg, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4,na.rm=TRUE)

# LOAD RESERVOIRS LAYER
res_csv <- data.table::fread(paste0(site, "reservoir-drought-features-export"))
# res.sf <- st_as_sf(res_csv, wkt = 'Geometry')
res_csv.normal <- sqldf(paste('SELECT * FROM res_csv WHERE Drought_Status_propcode = 0',sep=""))
res_csv.watch <- sqldf(paste('SELECT * FROM res_csv WHERE Drought_Status_propcode = 1',sep=""))
res_csv.warning <- sqldf(paste('SELECT * FROM res_csv WHERE Drought_Status_propcode = 2',sep=""))
res_csv.emergency <- sqldf(paste('SELECT * FROM res_csv WHERE Drought_Status_propcode = 3',sep=""))
res.sf.normal <- st_as_sf(res_csv.normal, wkt = 'Geometry')
res.sf.watch <- st_as_sf(res_csv.watch, wkt = 'Geometry')
res.sf.warning <- st_as_sf(res_csv.warning, wkt = 'Geometry')
res.sf.emergency <- st_as_sf(res_csv.emergency, wkt = 'Geometry')

# LOAD STREAMGAGE LAYER
gage_csv <- data.table::fread(paste0(site, "streamflow-drought-timeseries-all-export"))
gage_csv <-sqldf(paste('SELECT *
                        FROM gage_csv
                        WHERE drought_evaluation_region IS NOT "" '
                       ,sep=""))
gage.sf <- st_as_sf(gage_csv, wkt = 'Geometry')
# create lat and lon columns from WKT column
gage.sf <- gage.sf %>% dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                                     lat = sf::st_coordinates(.)[,2])

# LOAD WELL LAYER
well_csv <- data.table::fread(paste0(site, "groundwater-drought-timeseries-all-export"))
well.sf <- st_as_sf(well_csv, wkt = 'Geometry')
# create lat and lon columns from WKT column
well.sf <- well.sf %>% dplyr::mutate(lon = sf::st_coordinates(.)[,1],
                                     lat = sf::st_coordinates(.)[,2])

######################################################################################################
# Generate Map #######################################################################################
######################################################################################################

 finalmap.obj <- basemap.obj + 
                  # fips.gg +
                 geom_sf(data = fips.sf,aes(fill = factor(col)),lwd=0.4,
                         col = "black", alpha = 0.5, inherit.aes = FALSE, show.legend =TRUE)+
                 theme(#legend.position = c(0.305, 0.782),
                       legend.position = c(0.225, 0.78),
                       legend.title=element_text(size=9),
                       legend.text=element_text(size=8),
                       aspect.ratio = 12.05/16,
                       legend.box = "horizontal",
                       legend.spacing.x = unit(0.08, 'cm')
                       ) +
                 guides(fill=guide_legend(ncol=2))+
                 scale_fill_manual(name = "Drought Evaluation Regions",
                                   values = c("khaki1","slateblue2","darkolivegreen2","blue4","chocolate1",
                                              "darkcyan","darkkhaki","indianred1","aquamarine","lightpink",
                                              "chartreuse4","dodgerblue","bisque1","white"),
                                   labels = c("Big Sandy","Chowan","Eastern Shore","Middle James","New River",
                                              "Northern Coastal Plain","Northern Piedmont","Northern Virginia",
                                              "Roanoke","Shenandoah","Southeast Virginia","Upper James","York James","white")
                                   )+
                rivs.gg +
                geom_sf(data = res.sf.normal, color="#5CC85C",fill="black",lwd=1.0, inherit.aes = FALSE, show.legend =FALSE) +
                geom_sf(data = res.sf.watch, color="#FFFF33",lwd=1.0, inherit.aes = FALSE, show.legend =FALSE) +
                geom_sf(data = res.sf.warning, color="#FFCC33",lwd=1.0, inherit.aes = FALSE, show.legend =FALSE) +
                geom_sf(data = res.sf.emergency, color="#B80000",lwd=1.0, inherit.aes = FALSE, show.legend =FALSE) +
                geom_point(data = gage.sf, aes(color=factor(nonex_pct_propcode), x = lon, y = lat), pch = 17, size = 3, show.legend =FALSE) +
                geom_point(data = well.sf, aes(color=factor(nonex_pct_propcode), x = lon, y = lat), pch = 19, size = 3) +
                scale_color_manual(values = c("0" = "#5CC85C", "1" = "#FFFF33", "2" = "#FFCC33", "3" = "#B80000"),
                                   name="Indicator Status",
                                   labels=c("0" = "Normal", "1" = "Watch", "2" = "Warning", "3" = "Emergency"),
                                   guide = "none") +
                # add last updated text to bottom right
                annotate("rect", xmin = -76.9, xmax = -75.1, ymin = 35.3, ymax =35.5,alpha= 0.75,fill = "white") +
                annotate("text", x = -76.0, y = 35.4,label = paste0("Updated: ",Sys.Date()), color="black",size=3, fontface="italic")
  
deqlogo <- png::readPNG(paste(dependencies,"HiResDEQLogo.png",sep=''))
deqlogo <- grid::rasterGrob(deqlogo, interpolate=TRUE)
indicators_legend <- png::readPNG(paste(dependencies,"indicators_legend.png",sep=''))
indicators_legend <- grid::rasterGrob(indicators_legend, interpolate=TRUE)
drought_map_draw <- finalmap.obj + patchwork::inset_element(p = indicators_legend, left = 0.45, bottom = 0.81, right = 0.91, top = 0.996) +
                                   patchwork::inset_element(p = deqlogo, left = 0.01, bottom = 0.013, right = 0.2, top = 0.12) 

ggsave(plot = drought_map_draw, file = paste0(export_path, "virginia_drought_indicators.png",sep = ""), width=6.5, height=4.95) #FINAL MAP SAVES HERE

#############################################################################################







