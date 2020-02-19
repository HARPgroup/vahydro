library(sf) # needed for st_read()
library(wicket) #needed for sp_convert() 

######################################################################################################
# HUC6
poly_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/WBD.gdb"
poly_layer_name <- 'WBDHU6' 

# read in polygons
st <- st_read(poly_path, poly_layer_name)

# format dataframe for export
#st.df <- data.frame(st)
#st.df <- st.df[1,]
#data.frame(st.df$SHAPE)
#st.df$geometry <- data.frame(st.df$SHAPE)
st.geom <- as_Spatial(st_geometry(st))
hUC6df <- data.frame('HUC6' = as.character(st$HUC6),
                     'name' = as.character(st$NAME),
                     'geom'= sp_convert(st.geom, group = TRUE)
)
write.table(hUC6df, file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/HUC6.tsv', quote=FALSE, sep='\t', row.names = FALSE)

######################################################################################################
