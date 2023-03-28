basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_functions/model_geoprocessor.R")

#------------------------------------------
# plotname <- "all"
# segswhere <- "hydrocode NOT LIKE '%0000_0000'"
plotname <- "potomac"
segswhere <- "hydrocode LIKE '%wshed_P%'"
scenario_a <- list(ftype="vahydro",model_version="vahydro-1.0",runid="runid_11")
scenario_b <- list(ftype="cbp60",model_version="cbp-6.0",runid="hsp2_2022")
#------------------------------------------


################################################################################
# retrieve segments & metric data
# model_data <- data.frame(
#   'ftype' = scenario_b$ftype,
#   'model_version' = scenario_b$model_version,
#   'runid' = scenario_b$runid,
#   'metric' = c('Qout'),
#   'runlabel' = c('Qout')
# )
# model_data <- om_vahydro_metric_grid(metric, model_data, ds = ds)

model_data <- data.frame(
  'ftype' = c(scenario_a$ftype, scenario_b$ftype),
  'model_version' = c(scenario_a$model_version, scenario_b$model_version),
  'runid' = c(scenario_a$runid, scenario_b$runid),
  'metric' = c('Qout', 'Qout'),
  'runlabel' = c('scenario_a_Qout', 'scenario_b_Qout')
)
model_data <- om_vahydro_metric_grid(metric, model_data, ds = ds)

watersheds <- sqldf(paste0("
  SELECT *
  FROM model_data
  WHERE ",segswhere,";
  "))
################################################################################
################################################################################
# add geom column
df_add_geom <- function(watersheds) {
  watersheds$geom <- NA
  #i<-1
  for (i in 1:length(watersheds[,1])){
    print(paste(i," in ",length(watersheds[,1])," (",watersheds$hydrocode[i],")",sep=""))
    watershed_feature <- RomFeature$new(ds, list(hydroid = watersheds$featureid[i]), TRUE)
    watersheds$geom[i] <- watershed_feature$geom
  }
  return(watersheds)
}
################################################################################
################################################################################
# convert to sp layer
df_to_sp <- function(watersheds) {
  print(paste(1," in ",length(watersheds[,1])," (",watersheds$hydrocode[1],")",sep=""))
  rsegs_layer_sp <- sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom[1]), data=data.frame(watersheds[1,1:ncol(watersheds)-1]))
  #i<-2
  for (i in 2:length(watersheds[,1])){
    print(paste(i," in ",length(watersheds[,1])," (",watersheds$hydrocode[i],")",sep=""))
    rseg_sp <- sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom[i]), data=data.frame(watersheds[i,1:ncol(watersheds)-1]), match.ID = FALSE)
    rsegs_layer_sp <- rbind(rsegs_layer_sp, rseg_sp)
  }
return(rsegs_layer_sp)
}
################################################################################
################################################################################
# polygons_a <- df_to_sp(df_add_geom(watersheds))
# polygons_b <- df_to_sp(df_add_geom(watersheds))
polygons <- df_to_sp(df_add_geom(watersheds))
################################################################################
################################################################################

# map 
filename <- paste0("TEST9.png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)

# plot(polygons, axes = 1, main=paste0(plotname,"\n",segswhere), cex.main=2, cex.axis=2.5, border = "black")

# spplot(polygons_a, zcol="Qout", col.regions=gray(seq(0,1,.01)))
sp::spplot(polygons, zcol="scenario_b_Qout",
           col.regions=gray(rev(seq(0,1,.01))),
           main=paste0(plotname,"\n",segswhere)
           # par.settings=list(fontsize=list(text=40))
           # par.settings=list(fontsize=list(text=40),
           #                   par.main.text=list(text=5)
           #                   ),
           # legend = c("test")
           )
dev.off()


# spplot(rsegs_layer_sp, zcol="Qout", col.regions=gray(seq(0,1,.01)))
################################################################################
################################################################################


# # process rseg layer
# scenario <- c("vahydro-1.0","runid_11")
# rsegs_sp <- model_geoprocessor(scenario,segswhere)
# rsegs_sf <- st_as_sf(rsegs_sp)
# st_crs(rsegs_sf) <- 4326 
# 
# rsegs_centroids <- rgeos::gCentroid(rsegs_sp,byid=TRUE)
# rsegs_labels <- as.data.frame(sf::st_coordinates(st_as_sf(rsegs_centroids)))
# rsegs_labels$NAME <- rsegs_sf$riverseg
################################################################################
################################################################################




# retrieve & format geometry data
watershed_feature <- RomFeature$new(ds, list(hydroid = watersheds$featureid[1]), TRUE)
watershed_wkt <- watershed_feature$geom
watersheds$geom <- ""
watersheds$geom[1] <- watershed_wkt
# polygons_sp <- sp::SpatialPolygonsDataFrame(readWKT(watershed_wkt), data=data.frame(hydrocode=watersheds$hydrocode[1],riverseg=watersheds$riverseg[1]))
####polygons_sp <- sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom[1]),data=watersheds[1,1:ncol(watersheds)-1])

# polygons_sp_test <- sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom[1]),data=watersheds[1,1:ncol(watersheds)-1])
# polygons_sp_test$Qout
# 
# filename <- paste0("Model_Map_TEST.png")
# png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
# plot(polygons_sp_test, col = polygons_sp_test$Qout)
# dev.off()



if (length(watersheds[,1]) > 1){
  #i<-2
  for (i in 2:length(watersheds[,1])){
    print(paste(i," in ",length(watersheds[,1]),sep=""))
    # featureid <- watersheds$featureid[i]
    # hydrocode <- watersheds$hydrocode[i]
    # riverseg <- watersheds$riverseg[i]
    
    # watershed_feature <- RomFeature$new(ds, list(hydroid = featureid), TRUE)
    watershed_feature <- RomFeature$new(ds, list(hydroid = watersheds$featureid[i]), TRUE)
    watershed_wkt <- watershed_feature$geom
    watersheds$geom[i] <- watershed_wkt
    # polygons_sp <- rbind(polygons_sp, sp::SpatialPolygonsDataFrame(readWKT(watershed_wkt), data.frame(hydrocode=hydrocode,riverseg=riverseg)))
    #### polygons_sp <- rbind(polygons_sp, sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom[i]),data=watersheds[i,1:ncol(watersheds)-1]))
    
  }
}


polygons_a <- sp::SpatialPolygonsDataFrame(readWKT(watersheds$geom),data=watersheds[,1:ncol(watersheds)-1])


polygons_a <- polygons_sp
polygons_b <- polygons_sp
################################################################################

# process geo data
# polygons_a <- model_geoprocessor(scenario_a,segswhere)
# polygons_b <- model_geoprocessor(scenario_b,segswhere)

# generate & save plot figure
filename <- paste0("Model_Map_",scenario_a$ftype,scenario_a$model_version,scenario_a$runid,"_",scenario_b$ftype,scenario_b$model_version,scenario_b$runid,"_",plotname,".png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
# plot(polygons_a, axes = 1, main=plotname, cex.main=3.5, cex.axis=2.5, border = "black")
plot(polygons_a, axes = 1, main=paste0(plotname,"\n",segswhere), cex.main=2, cex.axis=2.5, border = "black")
plot(polygons_b, col = "blue", add = T)
legend("topleft", legend=c(paste0(scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(polygons_a),")"), 
                           paste0(scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(polygons_b),")")), 
       fill = c("white","blue"), cex=3.5)
dev.off()