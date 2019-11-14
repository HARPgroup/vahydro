install.packages('elevatr')
install.packages('rgdal')
library('elevatr')
library('rgdal')
examp_df <- data.frame(x = -76.271116944444, y =36.70)
prj_dd <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
df_elev_epqs <- get_elev_point(examp_df, prj = prj_dd, src = "epqs")
