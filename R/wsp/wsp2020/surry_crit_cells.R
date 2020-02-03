require(sqldf)
require(rgdal)
#prevents scientific notation
options(scipen = 20)

mp_all <- read.csv(file = "U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\1-31-2020\\wsp2020.mp.all.csv")

surry_only <- sqldf("SELECT *
                      FROM mp_all
                    where fips_code = 51181")

summary(surry_only)
summary_by_type <- sqldf("SELECT  MP_bundle, facility_ftype, sum(mp_2020_mgy), sum(mp_2040_mgy),sum(mp_2020_mgy)/365 as mp_2020_mgd, sum(mp_2040_mgy)/365 as mp_2040_mgd
                         FROM surry_only
                         GROUP BY  MP_bundle") 

#read in critical cells shapefile
crit_cells <- readOGR("U:\\OWS\\Report Development\\VCPM VESM Simulation Reports\\2017 Annual Simulation Report\\2017 VESM Critical_Surface", "ES_Critical_Surface")

crit <- spTransform(crit_cells, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
crit@data$id <- rownames(crit@data)
crit.df <- fortify(crit)
crit.df <- merge(crit.df, crit@data, by = 'id')

#run basemap_template script 
map + 
  geom_polygon(aes(fill = Shape_Area), color = 'black', size = 0.1) +
  geom_path(data = crit.df, aes(x =long, y = lat, color = order), size = 0.1)  +
  guides(fill=guide_colorbar(title="Legend\nTitle (Unit)")) +
  theme(legend.justification=c(0,1), legend.position=c(0,1)) +
  xlab('Longitude (deg W)') + ylab('Latitude (deg N)')+
  scale_fill_gradient2(low = 'brown', mid = 'white', high = 'green') +
  north(bbDF, location = 'topright', symbol = 12, scale=0.1)+
  scalebar(bbDF, location = 'bottomleft', dist = 100, dist_unit = 'km', 
           transform = TRUE, model = 'WGS84',st.bottom=FALSE, 
           st.size = 3.5, st.dist = 0.0285,
           anchor = c(
             x = (((extent$x[2] - extent$x[1])/2)+extent$x[1])-1.1,
             y = extent$y[1]+(extent$y[1])*0.001
           ))
