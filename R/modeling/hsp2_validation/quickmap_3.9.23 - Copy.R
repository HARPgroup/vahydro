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
segswhere <- "hydrocode LIKE 'P%'"
scenario_a <- list(ftype="vahydro",model_version="vahydro-1.0",runid="runid_11")
scenario_b <- list(ftype="cbp60",model_version="cbp-6.0",runid="hsp2_2022")
#------------------------------------------


################################################################################
# retrieve segments & metric data
model_data <- data.frame(
  'ftype' = scenario_b$ftype,
  'model_version' = scenario_b$model_version,
  'runid' = scenario_b$runid,
  'metric' = c('Qout'),
  'runlabel' = c('Qout')
)
# model_data <- om_vahydro_metric_grid(metric, model_data, ds = ds)
model_data <- om_vahydro_metric_grid(metric=model_data$metric,
                                     runids=model_data,
                                     featureid = 'all',
                                     entity_type = 'dh_feature',
                                     bundle = 'watershed',
                                     ftype = model_data$ftype,
                                     model_version = model_data$model_version,
                                     base_url = "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export",
                                     ds = ds)

#----------------------------------------
# model_data <- data.frame(
#   'ftype' = c(scenario_a$ftype, scenario_b$ftype),
#   'model_version' = c(scenario_a$model_version, scenario_b$model_version),
#   'runid' = c(scenario_a$runid, scenario_b$runid),
#   'metric' = c('Qout', 'Qout'),
#   'runlabel' = c('scenario_a_Qout', 'scenario_b_Qout')
# )
# # model_data <- om_vahydro_metric_grid(metric, model_data, ds = ds)
# model_data <- om_vahydro_metric_grid(metric=metric, 
#                                      runids=model_data, 
#                                      featureid = 'all',
#                                      entity_type = 'dh_feature',
#                                      bundle = 'watershed',
#                                      # ftype = model_data$ftype,
#                                      # model_version = model_data$model_version,
#                                      base_url = "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export",
#                                      ds = ds)


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

# plotvar = "scenario_b_Qout"
# plotvar = "featureid"
plotvar = "Qout"
  
# map 
filename <- paste0("TEST13.png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)

# plot(polygons, axes = 1, main=paste0(plotname,"\n",segswhere), cex.main=2, cex.axis=2.5, border = "black")

# spplot(polygons_a, zcol="Qout", col.regions=gray(seq(0,1,.01)))
sp::spplot(polygons, zcol=plotvar,
           col.regions=gray(rev(seq(0,1,.01))),
           colorkey = list(space = "left", height = 0.8, title=plotvar),
           main=paste0(plotname,"\n",segswhere),
           sub=c(paste0("Scenario A: ",scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(na.omit(watersheds$scenario_b_Qout)),")\n",
                        "Scenario B: ",scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(na.omit(watersheds$scenario_a_Qout)),")")),
           par.settings=list(fontsize=list(text=40))
           )
dev.off()

################
