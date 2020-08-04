library('rjson') # must do unloadNamespace('jsonlite')
# OR
library('jsonlite') # must do unloadNamespace('rjson')
# Facility monthly variation in demand as % of annual
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_feature/all/all/wd_current_mon_factors"
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/4824507/all/consumption_monthly"
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/all/all/consumption_monthly"

# rjson
xfile <-  fromJSON(file = fname)
# jsonlite
xfile <-  fromJSON(fname)
adf <- as.data.frame(xfile$entity_properties)



for (i in 1:length(xfile$entity_properties)) {
  # jsonlite
  xfact<- as.data.frame(fromJSON(xfile$entity_properties[[i]]$property$prop_matrix))
  
  mofrac <- xfact[c('xFrac', 'xFrac.1', 'xFrac.2', 'xFrac.3', 'xFrac.4', 'xFrac.5', 'xFrac.6', 'xFrac.7', 'xFrac.8', 'xFrac.9', 'xFrac.10', 'xFrac.11')]
                    
  # rjson
  xfact <- fromJSON(xfile$entity_properties[[i]]$property$prop_matrix)
    fracmo <- mofrac(c(xFrac, xFrac.1, xFrac.2, xFrac.3, xFrac.4, xFrac.5, xFrac.6, xFrac.7, xFrac.8, xFrac.9, xFrac.10, xFrac.11
                     
  for (j in 1:12) {
    dmx[j,'xMonth'] <- xfact[[j]]$xMonth
  }
}

xfactdf <- as.data.frame(xfact)
nrow(xfile$entity_properties[[3]])
fromJSON(xfile$entity_properties[[,]]$property$prop_matrix)

