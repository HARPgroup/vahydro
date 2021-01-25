map.divs <- function(RSeg_data,rseg_border,color_scale,divs){
  

print(length(divs))  
  
  
  
#DIVISIONS TO BE USED IN 7 MAPPING "BINS"
# div_min <- divs[1]
# div2 <- divs[2]
# # div2 <- divs[2] 
# # div3 <- divs[3] 
# # div4 <- divs[4] 
# # div5 <- divs[5] 
# 
# div_m1 <- divs[length(divs)-1] 
# div_max <- divs[length(divs)] 
#   
  
#INITIATE COLOR AND LABEL LISTS
color_values <- list()
label_values <- list()
layers <- list()

fill_cols <- c("antiquewhite","antiquewhite1","antiquewhite2","antiquewhite3","antiquewhite4","yellow4","yellowgreen")


######################################################################################################
### BIN LOOP #########################################################################################
######################################################################################################

# inner_divs <- divs[-1] #exclude div_min
# inner_divs <- inner_divs[-length(inner_divs)] #exclude last div


loop_length <- length(divs)-1

#i<-1
for (i in 1:loop_length){
    
    div_1 <- divs[i]
    div_2 <- divs[i+1]
    
    bin <- sqldf(paste("SELECT * FROM RSeg_data WHERE pct_chg < ",div_2, " AND pct_chg >= ",div_1))
    bin <- st_as_sf(bin, wkt = 'geom')
    
    if (nrow(bin) > 0) {
      geom <- geom_sf(data = bin,aes(geometry = geom,fill = fill_cols[i],colour=rseg_border), inherit.aes = FALSE)
      color_values <- rbind(color_values,color_scale[i])
      label_values <- rbind(label_values,paste(div_1,"% to ",div_2,"%",sep=""))
    } else  {
      geom <- geom_blank()
    }
    
    #print(geom)
    layers[[paste("geom_",i,sep="")]] <- geom

}

#print(layers)
layers <<- layers

div.out <- list(
              "color_values" = color_values,
              "label_values" = label_values,
              layers = layers
            )
  
  
  return(div.out)
} #close function  