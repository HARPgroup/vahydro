library(rgeos)
library(sf)

poly_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/WBD.gdb"
poly_layer_name <- 'WBDHU10' 

st <- st_read(poly_path, poly_layer_name)
sp <- as(st, "Spatial")


sp.df <- data.frame("HUC10"=character(),
                 "name"=character(),
                 "geom"=character(), 
                 stringsAsFactors=FALSE) 

#z <- 1
for (z in 1:length(sp$NAME)) {
print(paste("Executing feature ",z," of ", length(sp$NAME)," Name = ",as.character(sp[z,]$NAME),sep=""))
  sp.z <- sp[z,]
  sp.z_wkt <- writeWKT(sp.z, byid = FALSE)
  sp.df.z <- data.frame("HUC10" = as.character(sp[z,]$HUC10),
                        "name" = as.character(sp[z,]$NAME),
                        "geom" = sp.z_wkt)
  sp.df <- rbind(sp.df,sp.df.z)
}
length(sp.df[,1])


write.table(sp.df, file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/HUC10.tsv', quote=FALSE, sep='\t', row.names = FALSE)
