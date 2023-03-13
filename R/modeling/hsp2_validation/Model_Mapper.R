basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library("hydrotools")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_functions/model_geoprocessor.R")

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  segment_prefix <- as.character(argst[1])
  model_a <- as.character(argst[2])
  runid_a <- as.character(argst[3])
  model_b <- as.character(argst[4])
  runid_b <- as.character(argst[5])
  plotname <- as.character(argst[6])
} else {
  cat("River Segment Prefix (ex: 'JU' for upper James):")
  segment_prefix = readLines("stdin",n=1)
  cat("Model Version A (ex: 'vahydro-1.0'):")
  model_a = readLines("stdin",n=1)
  cat("Model Run ID A (ex: 'runid_11'):")
  runid_a = readLines("stdin",n=1)
  cat("Model Version B (ex: 'cbp-6.1'):")
  model_b = readLines("stdin",n=1)
  cat("Model Run ID B (ex: 'subsheds'):")
  runid_b = readLines("stdin",n=1)
  cat("Plot File base name:")
  plotname = readLines("stdin",n=1)
}
# Ex: 
# segment_prefix = 'J'
# model_a = 'vahydro-1.0'
# model_b = 'cbp-6.0'
# runid_a = 'runid_11'
# runid_b = 'subsheds'
segswhere <- paste0("hydrocode LIKE '%_", segment_prefix ,"%'")
scenario_a <- c(model_a,runid_a)
scenario_b <- c(model_b,runid_b)

################################################################################

# process geo data
polygons_a <- model_geoprocessor(ds, scenario_a,segswhere)
polygons_b <- model_geoprocessor(ds, scenario_b,segswhere)

# generate & save plot figure
filename <- paste0("Model_Map_",scenario_a[1],scenario_a[2],"_",scenario_b[1],scenario_b[2],"_",plotname,".png")
png(file=paste(export_path,filename,sep=""), width=1500, height=1500)
# plot(polygons_a, axes = 1, main=plotname, cex.main=3.5, cex.axis=2.5, border = "black")
plot(polygons_a, axes = 1, main=paste0(plotname,"\n",segswhere), cex.main=2, cex.axis=2.5, border = "black")
plot(polygons_b, col = "blue", add = T)
legend("topleft", legend=c(paste0(scenario_a[1],", ",scenario_a[2], " (",length(polygons_a),")"), 
                           paste0(scenario_b[1],", ",scenario_b[2], " (",length(polygons_b),")")), 
       fill = c("white","blue"), cex=3.5)
dev.off()
