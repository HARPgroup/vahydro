basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
# source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_functions/model_geoprocessor.R")

#------------------------------------------
# plotname <- "all"
# segswhere_a <- "hydrocode NOT LIKE '%0000_0000'"
# segswhere_b <- "hydrocode NOT LIKE '%0000_0000'"

# plotname <- "york pamunkey"
# # segswhere_a <- "hydrocode LIKE '%wshed_YP%' AND hydrocode NOT LIKE '%_0000'" # exclude tidal segs
# segswhere_a <- "hydrocode LIKE '%wshed_YP%'"
# segswhere_b <- "hydrocode LIKE 'YP%'"

# plotname <- "york mattaponi"
# segswhere_a <- "hydrocode LIKE '%wshed_YM%'"
# segswhere_b <- "hydrocode LIKE 'YM%'"

plotname <- "rappahannock"
segswhere_a <- "hydrocode LIKE '%wshed_R%'"
segswhere_b <- "hydrocode LIKE 'R%'"


scenario_a <- list(ftype="vahydro",model_version="vahydro-1.0",runid="runid_11")
scenario_b <- list(ftype="cbp60",model_version="cbp-6.0",runid="hsp2_2022")
#------------------------------------------

flow_metric <- "Qout"
# flow_metric <- "l90_Qout"

################################################################################
# retrieve segments & metric data
scenario_a_data <- data.frame(
  'ftype' = scenario_a$ftype,
  'model_version' = scenario_a$model_version,
  'runid' = scenario_a$runid,
  'metric' = c(flow_metric),
  'runlabel' = c(flow_metric)
)
scenario_a_data <- om_vahydro_metric_grid(metric=scenario_a_data$metric,runids=scenario_a_data,ftype = scenario_a_data$ftype,ds = ds)

scenario_b_data <- data.frame(
  'ftype' = scenario_b$ftype,
  'model_version' = scenario_b$model_version,
  'runid' = scenario_b$runid,
  'metric' = c(flow_metric),
  'runlabel' = c(flow_metric)
)
scenario_b_data <- om_vahydro_metric_grid(metric=scenario_b_data$metric,runids=scenario_b_data,ftype = scenario_b_data$ftype,ds = ds)


watersheds_a <- sqldf(paste0("SELECT * FROM scenario_a_data WHERE ",segswhere_a,";"))
# watersheds_b <- sqldf(paste0("SELECT * FROM scenario_b_data WHERE ",segswhere_b,";"))



# rbPal <- colorRampPalette(c('lightcyan','dodgerblue4'))
# rbPal <- colorRampPalette(c('lightcyan','royalblue4'))
# map_cols <- rbPal(6)

# generate a color palette of 6 blues from lightcyan to royalblue4
map_cols <- colorRampPalette(c('lightcyan','royalblue4'))(6)

# place rsegs into bins based on metric value 
watersheds_b <-sqldf(paste('SELECT *,
                            CASE
                              WHEN ',flow_metric,' < ',as.numeric(quantile(scenario_b_data[,flow_metric],0.05)),' THEN "',map_cols[1],'"
                              WHEN ',flow_metric,' BETWEEN ',as.numeric(quantile(scenario_b_data[,flow_metric],0.05)),' AND ',as.numeric(quantile(scenario_b_data[,flow_metric],0.25)),' THEN "',map_cols[2],'"
                              WHEN ',flow_metric,' BETWEEN ',as.numeric(quantile(scenario_b_data[,flow_metric],0.25)),' AND ',as.numeric(quantile(scenario_b_data[,flow_metric],0.50)),' THEN "',map_cols[3],'"
                              WHEN ',flow_metric,' BETWEEN ',as.numeric(quantile(scenario_b_data[,flow_metric],0.50)),' AND ',as.numeric(quantile(scenario_b_data[,flow_metric],0.75)),' THEN "',map_cols[4],'"
                              WHEN ',flow_metric,' BETWEEN ',as.numeric(quantile(scenario_b_data[,flow_metric],0.75)),' AND ',as.numeric(quantile(scenario_b_data[,flow_metric],0.95)),' THEN "',map_cols[5],'"
                              WHEN ',flow_metric,' > ',as.numeric(quantile(scenario_b_data[,flow_metric],0.95)),' THEN "',map_cols[6],'"
                              ELSE "#FFFFFF"
                            END AS color
                            FROM scenario_b_data
                            WHERE ',segswhere_b,sep="")) 

# # place rsegs into bins based on metric value 
# watersheds_b <-sqldf(paste('SELECT *,
#                           CASE
#                             WHEN "Qout" < ',as.numeric(quantile(polygons_b$Qout,0.5)),' THEN ',map_cols[1],'
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.5)),' AND ',as.numeric(quantile(polygons_b$Qout,0.25)),' THEN ',map_cols[2],'
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.25)),' AND ',as.numeric(quantile(polygons_b$Qout,0.50)),' THEN ',map_cols[3],'
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.50)),' AND ',as.numeric(quantile(polygons_b$Qout,0.75)),' THEN ',map_cols[4],'
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.75)),' AND ',as.numeric(quantile(polygons_b$Qout,0.95)),' THEN ',map_cols[5],'
#                             WHEN "Qout" > ',as.numeric(quantile(polygons_b$Qout,0.95)),' THEN ',map_cols[6],'
#                             ELSE "#ffffff"
#                           END AS color
#                         FROM watersheds_b',sep=""))
################################################################################
################################################################################
# add geom column
# watersheds <- watersheds_b
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
polygons_a <- df_to_sp(df_add_geom(watersheds_a))
polygons_b <- df_to_sp(df_add_geom(watersheds_b))
# polygons <- df_to_sp(df_add_geom(watersheds))
################################################################################
################################################################################

# generate basic map
# paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
# filename <- paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
# png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
# plot(polygons_a, axes = 1, main=paste0(plotname,"\na:",segswhere_a,"   b:",segswhere_b), cex.main=2, cex.axis=2.5, border = "black")
# plot(polygons_b, col = "blue", add = T)
# legend("topleft", legend=c(paste0(scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(polygons_a),")"),
#                            paste0(scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(polygons_b),")")), fill = c("white","blue"), cex=3.5)
# dev.off()
################################################################################
################################################################################
################################################################################
################################################################################
# 
# 
# # place rsegs into bins based on metric value 
# polygons_b_bins <-sqldf(paste('SELECT *,
#                           CASE
#                             WHEN "Qout" < ',as.numeric(quantile(polygons_b$Qout,0.5)),' THEN 2
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.5)),' AND ',as.numeric(quantile(polygons_b$Qout,0.25)),' THEN 3
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.25)),' AND ',as.numeric(quantile(polygons_b$Qout,0.50)),' THEN 4
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.50)),' AND ',as.numeric(quantile(polygons_b$Qout,0.75)),' THEN 5
#                             WHEN "Qout" BETWEEN ',as.numeric(quantile(polygons_b$Qout,0.75)),' AND ',as.numeric(quantile(polygons_b$Qout,0.95)),' THEN 5
#                             WHEN "Qout" > ',as.numeric(quantile(polygons_b$Qout,0.95)),' THEN 6
#                             ELSE 0
#                           END AS color
#                         FROM polygons_b',sep="")) 

# as.numeric(quantile(polygons_b$Qout,0))


# color polygons by metric value
# rbPal <- colorRampPalette(c('lightcyan','dodgerblue4'))
# polygons_b$Col <- rbPal(10)[as.numeric(cut(polygons_b$Qout,breaks = 10))]

# generate map
filename <- paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",flow_metric,"_",plotname,".png")
# filename <- paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
plot(polygons_a, axes = 1, main=paste0(plotname,"\na:",segswhere_a,"   b:",segswhere_b), cex.main=2, cex.axis=2.5, border = "black")
# plot(polygons_b, col = "blue", add = T)
# plot(polygons_b, col = polygons_b$Qout, add = T)
# plot(polygons_b, col = polygons_b$Col, add = T)
plot(polygons_b, col = polygons_b$color, add = T)
legend("topleft", legend=c(paste0(scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(polygons_a),")"),
                           paste0(scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(polygons_b),")")), fill = c("white","royalblue4"), cex=3.5)

# legend("topright", legend=round(polygons_b$Qout), fill = polygons_b$Col, cex=3.5)
# legend("topright", col=rbPal(2), pch=19,
#        legend=c(round(range(polygons_b$Qout), 1)), cex=3.5)

# legend("topright", legend=c(1,5,10,20,500,1000,2000,3000,4000,5000), fill = rbPal(10), cex=3.5)

# legend("topright", legend=round(as.numeric(quantile(watersheds_b$Qout, c(0, 0.05, 0.25, 0.50, 0.75, 0.95, 1.0))),0), fill = c(map_cols,"#FFFFFF"), cex=3.5)

# legend("topright", legend=c("0-5%","5%-25%","25%-50%","50%-75%","75%-95%","95%-100%"), fill = map_cols, cex=3.5)
legend("topright", legend=c(paste0("0%-5%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.0)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],0.05)),0)),
                            paste0("5%-25%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.05)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],0.25)),0)),
                            paste0("25%-50%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.25)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],0.50)),0)),
                            paste0("50%-75%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.50)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],0.75)),0)),
                            paste0("75%-95%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.75)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],0.95)),0)),
                            paste0("95%-100%: ",round(as.numeric(quantile(watersheds_b[,flow_metric],0.95)),0),"-",round(as.numeric(quantile(watersheds_b[,flow_metric],1)),0))
                            ),
                            fill = map_cols, cex=2.5,
                            title = paste0(flow_metric," (cfs)"))


dev.off()

# as.numeric(quantile(watersheds_b$Qout, c(0, 0.05, 0.25, 0.50, 0.75, 0.95, 1.0)))
# watersheds_b$color

# quantile(watersheds_b$Qout, c(0, 0.05, 0.25, 0.50, 0.75, 0.95, 1.0))
# quantile(watersheds_b$Qout,0)
# legend=c("one","two","three","four","five","six")
################################################################################
################################################################################
################################################################################
################################################################################

