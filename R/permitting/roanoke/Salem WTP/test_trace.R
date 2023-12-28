
#test_site <- 'http://deq1.bse.vt.edu:81/d.alpha'
#site <- test_site
site <- 'http://deq1.bse.vt.edu:81/d.dh'

#rseg.hydroid <- 68193 #Seg right above SML
#rseg.hydroid <- 68327 #SALEM WTP
seg_up <- read.csv(paste(site,'watershed-trace-up-export',rseg.hydroid,sep='/'))

trace_up <- function (site, seg_up,length_2=100) {
    length_1 <- length(seg_up$hydroid)
  while (length_1 < length_2) {
    length_1 <- length(seg_up$hydroid)
    #####################################################################    
    segup_all <- seg_up
    #i <- 1
    for (i in 1:length(seg_up[,1])){
      seg_up_i <- seg_up[i,]
      hydroid_i <- seg_up_i$hydroid
      segs_above_i <- read.csv(paste(site,'watershed-trace-up-export',hydroid_i,sep='/'))
      
      if (isTRUE(length(segs_above_i$hydroid) == 0)){
        next
      } else {
        #z<-1
        for (z in 1:length(segs_above_i[,1])){
          seg_up_z <- segs_above_i[z,]
          if ((seg_up_z$hydroid %in% segup_all$hydroid) == FALSE){
            segup_all <- rbind(segup_all,seg_up_z)
            rownames(segup_all) <- 1:nrow(segup_all) 
          } #ONLY ADD SEG IF NOT ALREADY IN DATAFRAME
        } #CLOSE FOR  
      } #CLOSE IF ELSE
    } #CLOSE FOR
    seg_up <- segup_all
    #####################################################################       
    length_2 <- length(seg_up$hydroid)
    if (length_2 > length_1){
      next
    } else{
      print(paste('Total Number of Upstream Segments: ',length_1,sep=''))
      break
    }
  } #CLOSE WHILE LOOP
  return(seg_up)
} #CLOSE FUNCTION


upstream_segs <- trace_up(site,seg_up)

cat(paste(as.character(upstream_segs$hydroid),collapse=","))


