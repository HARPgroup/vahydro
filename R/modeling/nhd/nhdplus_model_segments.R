library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1

# beaver creek reservoir lon/lat -78.652281, 38.071266
start_point <- st_sf(
  id = 1, 
  geom = st_sfc(
    st_point(
      c(-78.551675, 38.137456)
    ), 
    crs = 4384
  )
)

out_point = sf::st_sfc(sf::st_point(c(-78.551675, 38.137456)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
nhd_out <- get_nhdplus(comid = comid)


sf_use_s2(FALSE)
#> Spherical geometry (s2) switched off
# this buffer, there has got to be a better way.  Maybe searching by NHD huc8 or something?
# the concern is, when I went with a uffer of 0.1, it only retrieved 28 features for Mechums
# but when I went above 0.2, I got the full 54 nhd+ features in Mechums
domain <- st_buffer(st_as_sfc(st_bbox(start_point)), .2)

# grab some sample data and plot the domain
nhd <- plot_nhdplus(bbox = st_bbox(domain))
cdf <- as.data.frame(nhd$catchment)

fldf <- as.data.frame(st_drop_geometry(nhd$flowline))
fldf <- fldf[,c("COMID","gnis_name", "FromNode", "ToNode")]

# beaver creek lake comid is 8567221
comid = 8567221
# the stuff upstream
bc_comids = get_UT(nhd$flowline, comid, distance = NULL)
bc_comids = (paste(bc_comids,collapse=', '))
bc_network <- sqldf(str_interp("select * from fldf where comid in (${bc_comids}) order by COMID"))
# Mechums just above the confluence with Moormans into SF Rivanna
comid = 8566905
mc_comids = get_UT(nhd$flowline, comid, distance = NULL)
mc_comids = (paste(mc_comids,collapse=', '))
mc_network <- sqldf(str_interp("select * from fldf where comid in (${mc_comids}) order by COMID"))
sqldf("select * from fldf where comid in ('8566975')")
sqldf("select * from fldf")

# Also plot the start point.
plot(st_geometry(st_transform(start_point, 3857)), 
     add = TRUE, col = "red", cex = 2)

start_point <- st_join(start_point, nhd$network_wtbd)

wb_out <- get_wb_outlet(lake_id = start_point$COMID, 
                        network = nhd$flowline)

plot_nhdplus(outlets = list(wb_out$comid), streamorder = 2)
