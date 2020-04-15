#SOURCE CURRENT MAP

######################################################################################################
######################################################################################################
#colnames(RSeg_data)
group_0_plus <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_13 >= 0")  
group_0_plus <- sqldf(group_0_plus)
group_0_plus <- st_as_sf(group_0_plus, wkt = 'geom')

if (nrow(group_0_plus) >0) {
  
  geom1 <- geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)
  color_values <- "darkolivegreen3"
  label_values <- ">= 0%"
                                                          
  } else  {
 
   geom1 <- geom_blank()
  
}
#-----------------------------------------------------------------------------------------------------
group_neg5_0 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_13 < 0 AND chg_11_to_13 >= -5")  
group_neg5_0 <- sqldf(group_neg5_0)
group_neg5_0 <- st_as_sf(group_neg5_0, wkt = 'geom')

if (nrow(group_neg5_0) >0) {
  
  geom2 <- geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'antiquewhite1'), inherit.aes = FALSE)
  color_values <- rbind(color_values,"cornflowerblue")
  label_values <- rbind(label_values,"-5% to 0%")
  
} else  {
  
  geom2 <- geom_blank()
  
}
#-----------------------------------------------------------------------------------------------------
group_neg10_neg5 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_13 < -5 AND chg_11_to_13 >= -10")  
group_neg10_neg5 <- sqldf(group_neg10_neg5)
group_neg10_neg5 <- st_as_sf(group_neg10_neg5, wkt = 'geom')

if (nrow(group_neg10_neg5) >0) {
  
  geom3 <- geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'antiquewhite2'), inherit.aes = FALSE)
  color_values <- rbind(color_values,"khaki2")
  label_values <- rbind(label_values,"-10% to -5%")
  
} else  {
  
  geom3 <- geom_blank()
  
}
#-----------------------------------------------------------------------------------------------------
group_neg20_neg10 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_13 < -10 AND chg_11_to_13 >= -20")  
group_neg20_neg10 <- sqldf(group_neg20_neg10)
group_neg20_neg10 <- st_as_sf(group_neg20_neg10, wkt = 'geom')

if (nrow(group_neg20_neg10) >0) {
  
  geom4 <- geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'antiquewhite3'), inherit.aes = FALSE)
  color_values <- rbind(color_values,"plum3")
  label_values <- rbind(label_values,"-20% to -10%")
  
} else  {
  
  geom4 <- geom_blank()
  
}
#-----------------------------------------------------------------------------------------------------
group_negInf_neg20 <- paste("SELECT *
                  FROM RSeg_data
                  WHERE chg_11_to_13 <= -20")  
group_negInf_neg20 <- sqldf(group_negInf_neg20)
group_negInf_neg20 <- st_as_sf(group_negInf_neg20, wkt = 'geom')

if (nrow(group_negInf_neg20) >0) {
  
  geom5 <- geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'antiquewhite4'), inherit.aes = FALSE)
  color_values <- rbind(color_values,"coral3")
  label_values <- rbind(label_values,"More than -20%")
  
} else  {
  
  geom5 <- geom_blank()
  
}
######################################################################################################

#colnames(RSeg_data)
source_current <- base_map +
  #no group on this layer, so don't inherit aes
  
#  geom_sf(data = RSeg_data,aes(geometry = geom,fill = 'aliceblue'), inherit.aes = FALSE,  show.legend=FALSE)+ 
  geom1 +
  geom2 +
  geom3 +
  geom4 +
  geom5 +
  #geom_sf(data = group_0_plus,aes(geometry = geom,fill = 'antiquewhite'), inherit.aes = FALSE)+ 
  # geom_sf(data = group_neg5_0,aes(geometry = geom,fill = 'antiquewhite1'), inherit.aes = FALSE)+ 
  # geom_sf(data = group_neg10_neg5,aes(geometry = geom,fill = 'antiquewhite2'), inherit.aes = FALSE)+ 
  # geom_sf(data = group_neg20_neg10,aes(geometry = geom,fill = 'antiquewhite3'), inherit.aes = FALSE)+ 
  #geom_sf(data = group_negInf_neg20,aes(geometry = geom,fill = 'antiquewhite4'), inherit.aes = FALSE)+ 
  
  # scale_fill_manual(values=c("darkolivegreen3","cornflowerblue","khaki2","plum3","coral3"),
  #                   name = "Legend",
  #                   labels = c(">= 0%",
  #                              "-5% to 0%",
  #                              "-10% to -5%",
  #                              "-20% to -10%",
#                              "More than -20%"))+

scale_fill_manual(values=color_values,
                  name = "Legend",
                  labels = label_values)+
  
  guides(fill = guide_legend(reverse=TRUE))
