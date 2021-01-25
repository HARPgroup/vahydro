map.divs <- function(RSeg_data,rseg_border,color_scale,divs){
  

#DIVISIONS TO BE USED IN 7 MAPPING "BINS"
div1 <- divs[1]
div2 <- divs[2] 
div3 <- divs[3] 
div4 <- divs[4] 
div5 <- divs[5] 
div6 <- divs[6] 
  
  
#INITIATE COLOR AND LABEL LISTS
color_values <- list()
label_values <- list()
######################################################################################################
### BIN 1 ############################################################################################
######################################################################################################
bin1 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div1))  
bin1 <- st_as_sf(bin1, wkt = 'geom')

if (nrow(bin1) > 0) {
  geom1 <- geom_sf(data = bin1,aes(geometry = geom,fill = 'antiquewhite',colour=rseg_border), inherit.aes = FALSE)
  color_values <- color_scale[1]
  label_values <- paste(" More than ",div1,"%",sep="")
} else  {
  geom1 <- geom_blank()
}
######################################################################################################
### BIN 2 ############################################################################################
######################################################################################################
bin2 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div2, "AND pct_chg >= ",div1))
bin2 <- st_as_sf(bin2, wkt = 'geom')

if (nrow(bin2) > 0) {
  geom2 <- geom_sf(data = bin2,aes(geometry = geom,fill = 'antiquewhite1',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div1,"% to ",div2,"%",sep=""))
} else  {
  geom2 <- geom_blank()
}
######################################################################################################
### BIN 3 ############################################################################################
######################################################################################################
bin3 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div3, "AND pct_chg >= ",div2))
bin3 <- st_as_sf(bin3, wkt = 'geom')

if (nrow(bin3) > 0) {
  geom3 <- geom_sf(data = bin3,aes(geometry = geom,fill = 'antiquewhite2',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[3])
  label_values <- rbind(label_values,paste(div2,"% to ",div3,"%",sep=""))
} else  {
  geom3 <- geom_blank()
}
######################################################################################################
### BIN 4 ############################################################################################
######################################################################################################
bin4 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div4, "AND pct_chg >= ",div3))
bin4 <- st_as_sf(bin4, wkt = 'geom')

if (nrow(bin4) > 0) {
  geom4 <- geom_sf(data = bin4,aes(geometry = geom,fill = 'antiquewhite3',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[4])
  label_values <- rbind(label_values,paste(div3,"% to ",div4,"%",sep=""))
} else  {
  geom4 <- geom_blank()
}
######################################################################################################
### BIN 5 ############################################################################################
######################################################################################################
bin5 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div5, "AND pct_chg >= ",div4))
bin5 <- st_as_sf(bin5, wkt = 'geom')

if (nrow(bin5) > 0) {
  geom5 <- geom_sf(data = bin5,aes(geometry = geom,fill = 'antiquewhite4',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[5])
  label_values <- rbind(label_values,paste(div4,"% to ",div5,"%",sep=""))
} else  {
  geom5 <- geom_blank()
}
######################################################################################################
### BIN 6 ############################################################################################
######################################################################################################
bin6 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div6, "AND pct_chg >= ",div5))
bin6 <- st_as_sf(bin6, wkt = 'geom')

if (nrow(bin6) > 0) {
  geom6 <- geom_sf(data = bin6,aes(geometry = geom,fill = 'aquamarine',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[6])
  label_values <- rbind(label_values,paste(div5,"% to ",div6,"%",sep=""))
} else  {
  geom6 <- geom_blank()
}
######################################################################################################
### BIN 7 ############################################################################################
######################################################################################################
bin7 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg >= ",div6))
bin7 <- st_as_sf(bin7, wkt = 'geom')

if (nrow(bin7) > 0) {
  geom7 <- geom_sf(data = bin7,aes(geometry = geom,fill = 'aquamarine1',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[7])
  label_values <- rbind(label_values,paste(">= ",div6,"%",sep=""))
} else  {
  geom7 <- geom_blank()
}  
  

div.out <- list(
              "color_values" = color_values,
              "label_values" = label_values,
              "layers" = list("geom7" = geom7,
                            "geom6" = geom6,
                            "geom5" = geom5,
                            "geom4" = geom4,
                            "geom3" = geom3,
                            "geom2" = geom2,
                            "geom1" = geom1)  
            )
  
  
  
  return(div.out)
} #close function  