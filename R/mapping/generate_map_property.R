source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_functions/mapgen.R")

# User Inputs: 

basepath='/var/www/R';
source("/var/www/R/config.R")

filename <- paste0("MagnoliaGreen_nhdplus_map.png")

# specify start point (typically intake location), map buffer is based on this point
start_point <- data.frame(lat = 37.415128974720155, lon = -77.7271085761693, label = "Intake")

# specify additional points to plot
points <- data.frame(lat=double(),lon=double(),label=character())
points <- rbind(points,data.frame(lat = 37.40402068694781, lon = -77.74288001411728, label = "12MG Pond"))
points <- rbind(points,data.frame(lat = 37.402823839033694, lon = -77.74452198900777, label = "7MG Pond"))

# specify usgs gage to plot
gageid <- "02036500"

# specify which rsegs to plot
segswhere <- "hydrocode LIKE 'vahydrosw_wshed_J%'"

# generate map gg object (simple example, using defaults)
# map_gg <- mapgen()

# generate map gg object (simple example, overriding defaults)
map_gg <- mapgen(start_point=start_point,
                 points=points,
                 gageid=gageid,
                 segswhere=segswhere)

# output map as png file
png(file=paste(export_path,filename,sep="/"), width=1500, height=1500)
map_gg
dev.off()