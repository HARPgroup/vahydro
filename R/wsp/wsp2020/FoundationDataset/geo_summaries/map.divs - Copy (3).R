map.divs <- function(RSeg_data,rseg_border,color_scale,divs){
  

#print(length(divs))  
  
  
  
#DIVISIONS TO BE USED IN 7 MAPPING "BINS"
div_min <- divs[1]
div2 <- divs[2]
# div2 <- divs[2] 
# div3 <- divs[3] 
# div4 <- divs[4] 
# div5 <- divs[5] 

div_m1 <- divs[length(divs)-1] 
div_max <- divs[length(divs)] 
  
  
#INITIATE COLOR AND LABEL LISTS
color_values <- list()
label_values <- list()
layers <- list()

fill_cols <- c("antiquewhite","antiquewhite1","antiquewhite2","antiquewhite3","antiquewhite4")
######################################################################################################
### BIN 1 ############################################################################################
######################################################################################################
bin1 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div_min))  
bin1 <- st_as_sf(bin1, wkt = 'geom')

if (nrow(bin1) > 0) {
  geom1 <- geom_sf(data = bin1,aes(geometry = geom,fill = fill_cols[1],colour=rseg_border), inherit.aes = FALSE)
  color_values <- color_scale[1]
  label_values <- paste(" More than ",div_min,"%",sep="")
} else  {
  geom1 <- geom_blank()
}

layers[[1]] <- geom1

######################################################################################################
### BIN 2 ############################################################################################
######################################################################################################
bin2 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div2, "AND pct_chg >= ",div_min))
bin2 <- st_as_sf(bin2, wkt = 'geom')

if (nrow(bin2) > 0) {
  geom2 <- geom_sf(data = bin2,aes(geometry = geom,fill = fill_cols[2],colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[2])
  label_values <- rbind(label_values,paste(div_min,"% to ",div2,"%",sep=""))
} else  {
  geom2 <- geom_blank()
}
layers[[2]] <- geom2
######################################################################################################
### BIN LOOP #########################################################################################
######################################################################################################

# inner_divs <- divs[-1] #exclude div_min
# inner_divs <- inner_divs[-length(inner_divs)] #exclude last div
# 
# #i<-1  
# for (i in 1:length(inner_divs)){
# 
#   div_i <- inner_divs[i]
#   
# bin5 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div_i, "AND pct_chg >= ",div_min))
# bin5 <- st_as_sf(bin5, wkt = 'geom')
# 
# if (nrow(bin5) > 0) {
#   geom5 <- geom_sf(data = bin5,aes(geometry = geom,fill = 'antiquewhite4',colour=rseg_border), inherit.aes = FALSE)
#   color_values <- rbind(color_values,color_scale[i])
#   label_values <- rbind(label_values,paste(div_min,"% to ",div_i,"%",sep=""))
# } else  {
#   geom5 <- geom_blank()
# }
# 
# }


#-----------
# for (x in 2:(length(divs)-1)) {
#   print(paste("LOOP ITERATION: ",x,sep=''))
#   divx <- divs[x]
#   fillx <- fill_cols[x]
# 
#   # print(divx)
#   # print(fillx)
#   # print(color_scale[x])
# 
#   binx <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",divx, "AND pct_chg >= ",divs[x-1]))
#   binx <- st_as_sf(binx, wkt = 'geom')
# 
#   if (nrow(binx) > 0) {
#     geomx <- geom_sf(data = binx,aes(geometry = geom,fill = fillx,colour=rseg_border), inherit.aes = FALSE)
#     color_values <- rbind(color_values,color_scale[x])
#     label_values <- rbind(label_values,paste(divs[x-1],"% to ",divx,"%",sep=""))
#   } else  {
# 
#     geomx <- geom_blank()
#   }
# 
#   #layers <- rbind(layers,geomx)
#   layers[[x+1]] <- geomx
# 
# }
######################################################################################################
######################################################################################################
######################################################################################################
######################################################################################################
### BIN m1 ############################################################################################
######################################################################################################
bin_m1 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div_m1, "AND pct_chg >= ",div_max))
bin_m1 <- st_as_sf(bin_m1, wkt = 'geom')

if (nrow(bin_m1) > 0) {
  geom_m1 <- geom_sf(data = bin_m1,aes(geometry = geom,fill = 'yellow4',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[length(divs)])
  label_values <- rbind(label_values,paste(div_m1,"% to ",div_max,"%",sep=""))
} else  {
  geom_m1 <- geom_blank()
}
layers[[length(divs)]] <- geom_m1
######################################################################################################
### BIN 7 ############################################################################################
######################################################################################################
bin7 <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg >= ",div_max))
bin7 <- st_as_sf(bin7, wkt = 'geom')

if (nrow(bin7) > 0) {
  geom7 <- geom_sf(data = bin7,aes(geometry = geom,fill = 'yellowgreen',colour=rseg_border), inherit.aes = FALSE)
  color_values <- rbind(color_values,color_scale[(length(divs)+1)])
  label_values <- rbind(label_values,paste(">= ",div_max,"%",sep=""))
} else  {
  geom7 <- geom_blank()
}  
  

#layers <- rbind(layers,geom7)
layers[[length(divs)+1]] <- geom7

#print("LAYERS:")
#print(layers)

# 
# print(color_values)
# print(label_values)


div.out <- list(
              "color_values" = color_values,
              "label_values" = label_values,
              "layers" = layers
            )
  
  
  
  return(div.out)
} #close function  