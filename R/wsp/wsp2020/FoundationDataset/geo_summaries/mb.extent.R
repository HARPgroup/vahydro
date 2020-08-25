mb.extent <- function(minorbasin,MinorBasins.csv){
  
  if (minorbasin %in% c('TU')) {
    
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.7
    xmax <- mb.centroid$lng + 1.1
    ymin <- mb.centroid$lat - 1.4
    ymax <- mb.centroid$lat + 1.4
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))
    
  } else if (minorbasin %in% c('MN','OR')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.5
    xmax <- mb.centroid$lng + 1.7
    ymin <- mb.centroid$lat - 1.6
    ymax <- mb.centroid$lat + 1.6
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))
    
  } else if (minorbasin %in% c('JL')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.15
    xmax <- mb.centroid$lng + 1.25
    ymin <- mb.centroid$lat - 1.2
    ymax <- mb.centroid$lat + 1.2
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('PU')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.4
    xmax <- mb.centroid$lng + 1.4
    ymin <- mb.centroid$lat - 1.4
    ymax <- mb.centroid$lat + 1.4
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('EL','ES')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1.2
    xmax <- mb.centroid$lng + 1.2
    ymin <- mb.centroid$lat - 1.35
    ymax <- mb.centroid$lat + 1.05
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
  } else if (minorbasin %in% c('PS')) { 
    mb.row <- paste('SELECT * FROM "MinorBasins.csv" WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 0.9
    xmax <- mb.centroid$lng + 1.1
    ymin <- mb.centroid$lat - 1
    ymax <- mb.centroid$lat + 1
    
    extent <- data.frame(x = c(xmin, xmax),y = c(ymin, ymax))   
    
    
  } else {
    
    
    mb.row <- paste('SELECT *
              FROM "MinorBasins.csv" 
              WHERE code == "',minorbasin,'"',sep="")
    mb.row <- sqldf(mb.row)
    
    mb.centroid <- wkt_centroid(mb.row$geom)
    
    xmin <- mb.centroid$lng - 1
    xmax <- mb.centroid$lng + 1
    ymin <- mb.centroid$lat - 1
    ymax <- mb.centroid$lat + 1
    
    extent <- data.frame(x = c(xmin, xmax),
                         y = c(ymin, ymax))
    
  }
  
  return(extent)
} #close function