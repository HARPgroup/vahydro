basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
# source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_functions/model_geoprocessor.R")

#------------------------------------------
# plotname <- "all"
# segswhere <- "hydrocode NOT LIKE '%0000_0000'"
# plotname <- "potomac"
# segswhere_a <- "hydrocode LIKE '%wshed_P%'"
# segswhere_b <- "hydrocode LIKE 'P%'"
# segswhere_a <- "hydrocode NOT LIKE '%0000_0000'"
# segswhere_b <- "hydrocode NOT LIKE '%0000_0000'"

plotname <- "york pamunkey"
segswhere_a <- "hydrocode LIKE '%wshed_YP%'"
segswhere_b <- "hydrocode LIKE 'YP%'"
scenario_a <- list(ftype="vahydro",model_version="vahydro-1.0",runid="runid_11")
scenario_b <- list(ftype="cbp60",model_version="cbp-6.0",runid="hsp2_2022")
#------------------------------------------


################################################################################
# retrieve segments & metric data
scenario_a_data <- data.frame(
  'ftype' = scenario_a$ftype,
  'model_version' = scenario_a$model_version,
  'runid' = scenario_a$runid,
  'metric' = c('Qout'),
  'runlabel' = c('Qout')
)
scenario_a_data <- om_vahydro_metric_grid(metric=scenario_a_data$metric,runids=scenario_a_data,ftype = scenario_a_data$ftype,ds = ds)

scenario_b_data <- data.frame(
  'ftype' = scenario_b$ftype,
  'model_version' = scenario_b$model_version,
  'runid' = scenario_b$runid,
  'metric' = c('Qout'),
  'runlabel' = c('Qout')
)
scenario_b_data <- om_vahydro_metric_grid(metric=scenario_b_data$metric,runids=scenario_b_data,ftype = scenario_b_data$ftype,ds = ds)


watersheds_a <- sqldf(paste0("SELECT * FROM scenario_a_data WHERE ",segswhere_a,";"))
watersheds_b <- sqldf(paste0("SELECT * FROM scenario_b_data WHERE ",segswhere_b,";"))
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

# color polygons by metric value
# rbPal <- colorRampPalette(c('lightcyan','dodgerblue4'))
# polygons_b$Col <- rbPal(100)[as.numeric(cut(polygons_b$Qout,breaks = 100))]

# generate map
paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
# generate & save plot figure
filename <- paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
plot(polygons_a, axes = 1, main=paste0(plotname,"\na:",segswhere_a,"   b:",segswhere_b), cex.main=2, cex.axis=2.5, border = "black")
plot(polygons_b, col = "blue", add = T)
# plot(polygons_b, col = polygons_b$Qout, add = T)
# plot(polygons_b, col = polygons_b$Col, add = T)
legend("topleft", legend=c(paste0(scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(polygons_a),")"), 
                           paste0(scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(polygons_b),")")), fill = c("white","blue"), cex=3.5)
# legend("topright", title="Qout",
#        legend=round(sort(polygons_b$Qout),1), fill=sort(polygons_b$Col, decreasing=TRUE), cex=3.5)
#        # legend=c(1,10,20,50,100), fill=sort(polygons_b$Col, decreasing=TRUE), cex=3.5)
# gradientLegend(valRange=c(polygons_b$Qout), n.seg=3, pos=.5, side=1)

# mtext(1:10,side=2,at=tail(seq(yb,yt,(yt-yb)/10),-1)-0.05,las=2,cex=0.7)
dev.off()
# 
# round(sort(polygons_b$Qout),1)
# 
# 
# as.numeric(cut(polygons_b$Qout,breaks = 10))
# 
# xl <- 1
# yb <- 1
# xr <- 1.5
# yt <- 2
# rect(
#   xl,
#   head(seq(yb,yt,(yt-yb)/10),-1),
#   xr,
#   tail(seq(yb,yt,(yt-yb)/10),-1),
#   col=rbPal(10)
# )
# mtext(1:10,side=2,at=tail(seq(yb,yt,(yt-yb)/10),-1)-0.05,las=2,cex=0.7)
# 
# 
# # rbPal <- colorRampPalette(c('lightcyan','dodgerblue4'))
# # # rbPal <- colorRampPalette(c('red','blue'))
# # polygons_b$Col <- rbPal(100)[as.numeric(cut(polygons_b$Qout,breaks = 100))]
# 
# # plot by metric
# # plotvar = "Qout"
# # filename <- paste0("TEST13.png")
# # png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
# # sp::spplot(polygons, zcol=plotvar,
# #            col.regions=gray(rev(seq(0,1,.01))),
# #            colorkey = list(space = "left", height = 0.8, title=plotvar),
# #            main=paste0(plotname,"\n",segswhere),
# #            sub=c(paste0("Scenario A: ",scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(na.omit(watersheds$scenario_b_Qout)),")\n",
# #                         "Scenario B: ",scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(na.omit(watersheds$scenario_a_Qout)),")")),
# #            par.settings=list(fontsize=list(text=40))
# #            )
# # dev.off()
# 
# ################

################################################################################
################################################################################

# rbPal <- colorRampPalette(c('red','blue'))
# rbPal <- colorRampPalette(c('lightblue1','black'))
# polygons_b$Col <- rbPal(100)[as.numeric(cut(polygons_b$Qout,breaks = 100))]
# 
# srt <- sort(round(polygons_b$Qout), decreasing=TRUE)
# as.numeric(quantile(srt))

paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
filename <- paste0("Model_Map_",scenario_a$ftype,"-",scenario_a$model_version,"-",scenario_a$runid,"__",scenario_b$ftype,"-",scenario_b$model_version,"-",scenario_b$runid,"_",plotname,".png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
plot(polygons_a, axes = 1, main=paste0(plotname,"\na:",segswhere_a,"   b:",segswhere_b), cex.main=2, cex.axis=2.5, border = "black")
plot(polygons_b, col = "blue", add = T)
# plot(polygons_b, col = polygons_b$Qout, add = T)
# plot(polygons_b, col = brewer.pal(polygons_b$Qout), add = T)
# plot(polygons_b, col = polygons_b$Col, add = T)
legend("topleft", legend=c(paste0(scenario_a$ftype,", ",scenario_a$model_version,", ",scenario_a$runid, " (",length(polygons_a),")"), 
                           paste0(scenario_b$ftype,", ",scenario_b$model_version,", ",scenario_b$runid, " (",length(polygons_b),")")), fill = c("white","blue"), cex=3.5)
# legend("topright", legend=round(polygons_b$Qout), fill = polygons_b$Col, cex=3.5)
# legend("topright", legend=sort(as.numeric(quantile(srt)), decreasing=TRUE), fill =rev(rbPal(5)), cex=3.5)

dev.off()




#sort(x, decreasing=TRUE)

