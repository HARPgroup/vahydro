library(ggplot2)
library(ggsn)
library(ggmap) #used for get_stamenmap, get_map
library(ggspatial) #annotation_north_arrow()

#FUNCTION DEFAULTS TO STATEWIDE EXTENTS
base.map <- function(baselayers.gg,extent=data.frame(x = c(-84, -75),y = c(35.25, 40.6)),
                     plot_margin = c(-0.5,0.2,-0.5,0.1),
                     plot_zoom = 9,
                     scale_bar = TRUE
){
  
  # LOAD gg-ready MAP LAYERS FROM THE baselayers.gg LIST 
  bb.gg <- baselayers.gg[[which(names(baselayers.gg) == "bb.gg")]]
  states.gg <- baselayers.gg[[which(names(baselayers.gg) == "states.gg")]]
  rivs.gg <- baselayers.gg[[which(names(baselayers.gg) == "rivs.gg")]]
  
  # tile_layer <- get_map(
  #   location = c(left = extent$x[1],
  #                bottom = extent$y[1],
  #                right = extent$x[2],
  #                top = extent$y[2]),
  #   source = "stamen", zoom = plot_zoom, maptype = "terrain-background"
  # )
  # #source = "osm", zoom = plot_zoom, maptype = "satellite" #good
  # base_layer <- ggmap(tile_layer)
  
  df <- data.frame(lat = 40.6, lon = -84) # Need to start with an sf for some reason
  df <- st_as_sf(x = df,                         
                 coords = c("lon", "lat"),
                 crs = st_crs(4326))
  
  
  map <- ggplot() +geom_sf(data=df)+
    #ADD STATE BORDER LAYER
    geom_path(data = states.gg,aes(x = long, y = lat, group = group), color="gray20",lwd=0.5,na.rm=TRUE) +
    
    #ADD RIVERS LAYER
    geom_path(data = rivs.gg, aes(x = long, y = lat, group = group), color="dodgerblue3",lwd=0.4,na.rm=TRUE) +

     #ADD BORDER LAYER
    geom_polygon(data = bb.gg,aes(x = long, y = lat, group = group), color="black", fill = NA,lwd=0.5,na.rm=TRUE)+
    
    #Bound to only area of interest
    coord_sf(xlim = extent$x, ylim = extent$y, expand = F) +
    
    #ADD NORTH BAR
    annotation_north_arrow(which_north = "grid", location = "tr",
                           height = unit(1, "cm"),
                           width = unit(1, "cm")
  )+
    
    #CUSTOMIZE THEME
    theme(plot.margin = unit(plot_margin, "cm"),
          plot.title = element_text(size=12),
          plot.subtitle = element_text(size=10),
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          panel.border = element_blank()) 
  
  if (isTRUE(scale_bar)){
    
    map <- map +
      
      #ADD SCALE BAR
      ggsn::scalebar(bb.gg, location = 'bottomleft', dist = 100, dist_unit = 'mi',
                     
                     transform = TRUE, model = 'WGS84',st.bottom=FALSE,
                     st.size = 3.5, st.dist = 0.0285,
                     anchor = c(
                       x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-1.8,
                       y = extent$y[1]+(extent$y[1])*0.001
                     ))
  }
  
  
  return(map)
}