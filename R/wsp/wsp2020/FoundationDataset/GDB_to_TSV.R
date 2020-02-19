library(sf) # needed for st_read()

######################################################################################################
# HUC6
poly_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/WBD.gdb"
poly_layer_name <- 'WBDHU6' 

# read in polygons
st <- st_read(poly_path, poly_layer_name)

# format dataframe for export
st.df <- data.frame(st)
#st.df <- st.df[1,]
#data.frame(st.df$SHAPE)
st.df$geometry <- data.frame(st.df$SHAPE)
hUC6df <- data.frame('HUC6' = as.character(st.df$HUC6),
                     'name' = as.character(st.df$NAME),
                     'geom'= st.df$geometry
)
write.table(hUC6df, file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/HUC6.tsv', quote=FALSE, sep='\t', row.names = FALSE)

######################################################################################################
# class(st)
# foo <- st[1,]$SHAPE
# class(foo)
# data.frame(foo)

foo <- as_Spatial(st_geometry(st[1,]))
class(foo)
library(wicket) #required for sp_convert() 
bar <- sp_convert(foo, group = TRUE)


st <- as_Spatial(st_geometry(st))
geom <- sp_convert(st, group = TRUE)

length(st)
######################################################################################################



readWKT(hUC6df[1,]$geometry)

library(rgeos)
class(st.df[1,]$geometry)
as.character(st.df[1,]$geometry)

library(stringr)
foo <- st.df[1,]$geometry
foo <- as.character(foo)
str_replace(foo, '\n', '')

sapply(hUC6df,class)
######################################################################################################
# data.frame(hUC6df[1,]$geom)
# sapply(st.df,class)
# sapply(hUC6df,class)

######################################################################################################
# HUC8
poly_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/WBD.gdb"
poly_layer_name <- 'WBDHU8' 

# read in polygons
st <- st_read(poly_path, poly_layer_name)

# format dataframe for export
st.df <- data.frame(st)
st.df$geometry <- data.frame(st.df$SHAPE)
hUC8df <- data.frame('HUC8' = as.character(st.df$HUC8),
                     'name' = as.character(st.df$NAME),
                     'geom'= st.df$geometry
)
write.table(hUC8df, file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/HUC8.tsv', quote=FALSE, sep='\t', row.names = FALSE)

######################################################################################################
######################################################################################################
# HUC10
poly_path <- "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/WBD.gdb"
poly_layer_name <- 'WBDHU10' 

# read in polygons
st <- st_read(poly_path, poly_layer_name)

# format dataframe for export
st.df <- data.frame(st)
st.df$geometry <- data.frame(st.df$SHAPE)
hUC10df <- data.frame('HUC10' = as.character(st.df$HUC10),
                     'name' = as.character(st.df$NAME),
                     'geom'= st.df$geometry
)
write.table(hUC10df, file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/HUC10.tsv', quote=FALSE, sep='\t', row.names = FALSE)

######################################################################################################
