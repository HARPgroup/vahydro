################################
#### *** Water Supply Element
################################
# dirs/URLs

#----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
#save_directory <-  "/var/www/html/data/proj3/out"
save_directory <- "C:/Users/nrf46657/Desktop/GitHub/vahydro/R/permitting/Salem WTP"
library(hydrotools)
# authenticate
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

# Load Local libs
library(stringr)
library(ggplot2)
library(sqldf)
library(ggnewscale)
library(dplyr)

# Read Args
# argst <- commandArgs(trailingOnly=T)
# pid <- as.integer(argst[1])
# elid <- as.integer(argst[2])
# runid <- as.integer(argst[3])
#omsite <- "http://deq1.bse.vt.edu"

pid <- 4827216 #Fac:Rseg model pid (Salem WTP:Roanoke River (Salem))
elid <- 306768 #Fac:Rseg model om_element_connection (Salem WTP:Roanoke River (Salem))
#runid <- 6011
runids <- c(200,2000,400,600)

#facdat <- om_get_rundata(elid, runid, site = omsite)

#i <- 1
for (i in 1:length(runids)) {
  
  runid <- runids[i]
    
  finfo <- fn_get_runfile_info(elid, runid,37, site= omsite)
  remote_url <- as.character(finfo$remote_url)
  dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
  syear = min(dat$year)
  eyear = max(dat$year)
  if (syear != eyear) {
    sdate <- as.Date(paste0(syear,"-10-01"))
    edate <- as.Date(paste0(eyear,"-09-30"))
  } else {
    # special case to handle 1 year model runs
    # just omit January in order to provide a short warmup period.
    sdate <- as.Date(paste0(syear,"-02-01"))
    edate <- as.Date(paste0(eyear,"-12-31"))
  }
  cols <- names(dat)
  
  
  # yrdat will be used for generating the heatmap with calendar years
  yrdat <- dat
  
  yr_sdate <- as.Date(paste0((as.numeric(syear) + 1),"-01-01"))
  yr_edate <- as.Date(paste0(eyear,"-12-31"))
  
  yrdat <- window(yrdat, start = yr_sdate, end = yr_edate);
  
  
  # Analyze unmet demands
  uds <- zoo(as.numeric(dat$unmet_demand_mgd), order.by = index(dat));
  udflows <- group2(uds, 'calendar');
  
  unmet90 <- udflows["90 Day Max"];
  ndx = which.max(as.numeric(unmet90[,"90 Day Max"]));
  unmet90 = round(udflows[ndx,]$"90 Day Max",6);
  unmet30 <- udflows["30 Day Max"];
  ndx1 = which.max(as.numeric(unmet30[,"30 Day Max"]));
  unmet30 = round(udflows[ndx,]$"30 Day Max",6);
  unmet7 <- udflows["7 Day Max"];
  ndx = which.max(as.numeric(unmet7[,"7 Day Max"]));
  unmet7 = round(udflows[ndx,]$"7 Day Max",6);
  unmet1 <- udflows["1 Day Max"];
  ndx = which.max(as.numeric(unmet1[,"1 Day Max"]));
  unmet1 = round(udflows[ndx,]$"1 Day Max",6);
  
  
  ##### HEATMAP
  # includes code needed for both the heatmap with counts and heatmap with counts and averages
  
  # Uses dat2 for heatmap calendar years
  # make numeric versions of syear and eyear
  num_syear <- as.numeric(syear) + 1
  num_eyear <- as.numeric(eyear)
  
  mode(yrdat) <- 'numeric'
  
  yrdatdf <- as.data.frame(yrdat)
  
  #ADD FINAL UNMET COLUMN
  #######################################################
  yrdatdf <- sqldf("select *,
                    CASE WHEN (unmet_demand_mgd - (2.6 - gw_demand_mgd) < 1) THEN 0
                  	  ELSE unmet_demand_mgd - (2.6 - gw_demand_mgd)
                    END AS final_unmet_demand_mgd
                    from yrdatdf")
  #colnames(yrdatdf)
  #######################################################
  
  # FOR QA PURPOSES ONLY
  yrdatdf_qa <- sqldf("select *
                    from yrdatdf
                    WHERE year = 2001 AND month = 10
                   ")
  
  #######################################################
  
  
  # yrmodat <- sqldf("SELECT month months, 
  #                         year years,
  #                         sum(unmet_demand_mgd) sum_unmet, 
  #                         count(*) count 
  #                   FROM yrdatdf 
  #                   WHERE unmet_demand_mgd > 0
  #                   GROUP BY month, year") #Counts sum of unmet_days by month and year
  
  #NEW VERSION -> USING FINAL UNMET DEMAND
  yrmodat <- sqldf("SELECT month months, 
                          year years,
                          sum(final_unmet_demand_mgd) sum_unmet, 
                          count(*) count 
                    FROM yrdatdf 
                    WHERE final_unmet_demand_mgd > 0
                    GROUP BY month, year") #Counts sum of unmet_days by month and year
  
  #converts unmet_mgd sums to averages for cells
  yrmodat$avg_unmet <- yrmodat$sum_unmet / yrmodat$count
  
  #Join counts with original data frame to get missing month and year combos then selects just count month and year
  yrmodat <- sqldf("SELECT * FROM yrdatdf LEFT JOIN yrmodat ON yrmodat.years = yrdatdf.year AND yrmodat.months = yrdatdf.month group by month, year")
  yrmodat <- sqldf('SELECT month, year, avg_unmet, count count_unmet_days FROM yrmodat GROUP BY month, year')
  
  #Replace NA for count with 0s
  yrmodat[is.na(yrmodat)] = 0
  
  ########################################################### Calculating Totals
  # monthly totals via sqldf
  mosum <- sqldf("SELECT  month, sum(count_unmet_days) count_unmet_days FROM yrmodat GROUP BY month")
  mosum$year <- rep(num_eyear+1,12)
  
  
  #JK addition 3/25/22: Cell of total days unmet in simulation period
  total_unmet_days <- sum(yrmodat$count_unmet_days)
  total_unmet_days_cell <- data.frame("month" = 13,
                                      "count_unmet_days" = as.numeric(total_unmet_days),
                                      "year" = num_eyear+1)
  
  
  #yearly sum
  yesum <-  sqldf("SELECT year, sum(count_unmet_days) count_unmet_days FROM yrmodat GROUP BY year")
  yesum$month <- rep(13,length(yesum$year))
  
  # yesum <- rbind(yesum,data.frame(year = "Total",
  #                                 count_unmet_days = 999,
  #                                 month = 13))
  
   
  # create monthly averages
  moavg<- sqldf('SELECT * FROM mosum')
  moavg$year <- moavg$year + 1
  moavg$avg <- round(moavg$count_unmet_days/((num_eyear-num_syear)+1),1)
  
  # create yearly averages
  yeavg<- sqldf('SELECT * FROM yesum')
  yeavg$month <- yeavg$month + 1
  yeavg$avg <- round(yeavg$count_unmet_days/12,1)
  
  # create x and y axis breaks
  y_breaks <- seq(syear,num_eyear+2,1)
  x_breaks <- seq(1,14,1)
  
  # create x and y labels
  y_labs <- c(seq(syear,eyear,1),'Totals', 'Avg')
  x_labs <- c(month.abb,'Totals','Avg')
  
  
  ############################################################### Plot and Save count heatmap
  # If loop makes sure plots are green if there is no unmet demand
  if (sum(mosum$count_unmet_days) == 0) {
    count_grid <- ggplot() +
      geom_tile(data=yrmodat, color='black',aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(aes(label=yrmodat$count_unmet_days, x=yrmodat$month, y= yrmodat$year), size = 3.5, colour = "black") +
      scale_fill_gradient2(low = "#00cc00", mid= "#00cc00", high = "#00cc00", guide = "colourbar",
                           name= 'Unmet Days') +
      theme(panel.background = element_rect(fill = "transparent"))+
      theme() + labs(title = 'Unmet Demand Heatmap', y=NULL, x=NULL) +
      scale_x_continuous(expand=c(0,0), breaks= x_breaks, labels=x_labs, position='top') +
      scale_y_reverse(expand=c(0,0), breaks=y_breaks, labels= y_labs) +
      theme(axis.ticks= element_blank()) +
      theme(plot.title = element_text(size = 12, face = "bold",  hjust = 0.5)) +
      theme(legend.title.align = 0.5)
    
    unmet <- count_grid + new_scale_fill() +
      geom_tile(data = yesum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_tile(data = mosum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = yesum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      geom_text(data = mosum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      scale_fill_gradient2(low = "#63D1F4", high = "#8A2BE2", mid="#63D1F4",
                           midpoint = mean(mosum$count_unmet_days), name= 'Total Unmet Days')
    
    total <- unmet + new_scale_fill() +
      geom_tile(data = total_unmet_days_cell, color='black',fill="grey",aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = total_unmet_days_cell, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days))
    
    #unmet_avg <- unmet + new_scale_fill()+
    unmet_avg <- total + new_scale_fill()+
      geom_tile(data = yeavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_tile(data = moavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_text(data = yeavg, size = 3.5, color='black', aes(x = month, y = year, label = avg)) +
      geom_text(data = moavg, size = 3.5, color='black', aes(x = month, y = year, label = avg))+
      scale_fill_gradient2(low = "#FFF8DC", mid = "#FFF8DC", high ="#FFF8DC",
                           name= 'Average Unmet Days', midpoint = mean(yeavg$avg))
  } else{
    count_grid <- ggplot() +
      geom_tile(data=yrmodat, color='black',aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(aes(label=yrmodat$count_unmet_days, x=yrmodat$month, y= yrmodat$year), size = 3.5, colour = "black") +
      scale_fill_gradient2(low = "#00cc00", high = "red",mid ='yellow',
                           midpoint = 15, guide = "colourbar",
                           name= 'Unmet Days') +
      theme(panel.background = element_rect(fill = "transparent"))+
      theme() + labs(title = 'Unmet Demand Heatmap', y=NULL, x=NULL) +
      scale_x_continuous(expand=c(0,0), breaks= x_breaks, labels=x_labs, position='top') +
      scale_y_reverse(expand=c(0,0), breaks=y_breaks, labels= y_labs) +
      theme(axis.ticks= element_blank()) +
      theme(plot.title = element_text(size = 12, face = "bold",  hjust = 0.5)) +
      theme(legend.title.align = 0.5)
    
    unmet <- count_grid + new_scale_fill() +
      geom_tile(data = yesum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_tile(data = mosum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = yesum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      geom_text(data = mosum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      scale_fill_gradient2(low = "#63D1F4", high = "#8A2BE2", mid='#CAB8FF',
                           midpoint = mean(mosum$count_unmet_days), name= 'Total Unmet Days')
    
    total <- unmet + new_scale_fill() +
      geom_tile(data = total_unmet_days_cell, color='black',fill="grey",aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = total_unmet_days_cell, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days))
    
    #unmet_avg <- unmet + new_scale_fill()+
    unmet_avg <- total + new_scale_fill()+  
      geom_tile(data = yeavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_tile(data = moavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_text(data = yeavg, size = 3.5, color='black', aes(x = month, y = year, label = avg)) +
      geom_text(data = moavg, size = 3.5, color='black', aes(x = month, y = year, label = avg))+
      scale_fill_gradient2(low = "#FFF8DC", mid = "#FFDEAD", high ="#DEB887",
                           name= 'Average Unmet Days', midpoint = mean(yeavg$avg))
    
  }
  
  
  fname2 <- paste(save_directory,paste0('fig.unmet_heatmap_gw.',elid, '.', runid, '.png'),sep = '/')
  
  #furl2 <- paste(save_url, paste0('fig.unmet_heatmap.',elid, '.', runid, '.png'),sep = '/')
  
  ggsave(fname2,plot = unmet_avg, width= 7, height=7)
  
  print(paste('File saved to save_directory:', fname2))
  
  #vahydro_post_metric_to_scenprop(scenprop$pid, 'dh_image_file', furl2, 'fig.unmet_heatmap', 0.0, ds)
  
  ###################################### Plot and save Second unmet Demand Grid
  # contains count/ Avg unmet demand mgd
  if (sum(mosum$count_unmet_days) == 0) {
    count_grid <- ggplot() +
      geom_tile(data=yrmodat, color='black',aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(aes(label=paste(yrmodat$count_unmet_days,' / ',round(yrmodat$avg_unmet,1), sep=''),
                    x=yrmodat$month, y= yrmodat$year), size = 3.5, colour = "black") +
      scale_fill_gradient2(low = "#00cc00", mid= "#00cc00", high = "#00cc00", guide = "colourbar",
                           name= 'Unmet Days') +
      theme(panel.background = element_rect(fill = "transparent"))+
      theme() + labs(title = 'Unmet Demand Heatmap', y=NULL, x=NULL) +
      scale_x_continuous(expand=c(0,0), breaks= x_breaks, labels=x_labs, position='top') +
      scale_y_reverse(expand=c(0,0), breaks=y_breaks, labels= y_labs) +
      theme(axis.ticks= element_blank()) +
      theme(plot.title = element_text(size = 12, face = "bold",  hjust = 0.5)) +
      theme(legend.title.align = 0.5)
    
    unmet <- count_grid + new_scale_fill() +
      geom_tile(data = yesum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_tile(data = mosum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = yesum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      geom_text(data = mosum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      scale_fill_gradient2(low = "#63D1F4", high = "#8A2BE2", mid="#63D1F4",
                           midpoint = mean(mosum$count_unmet_days), name= 'Total Unmet Days')
    
    total <- unmet + new_scale_fill() +
      geom_tile(data = total_unmet_days_cell, color='black',fill="grey",aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = total_unmet_days_cell, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days))
    
    #unmet_avg <- unmet + new_scale_fill()+
    unmet_avg <- total + new_scale_fill()+
      geom_tile(data = yeavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_tile(data = moavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_text(data = yeavg, size = 3.5, color='black', aes(x = month, y = year, label = avg)) +
      geom_text(data = moavg, size = 3.5, color='black', aes(x = month, y = year, label = avg))+
      scale_fill_gradient2(low = "#FFF8DC", mid = "#FFF8DC", high ="#FFF8DC",
                           name= 'Average Unmet Days', midpoint = mean(yeavg$avg))
  } else{
    count_grid <- ggplot() +
      geom_tile(data=yrmodat, color='black',aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(aes(label=paste(yrmodat$count_unmet_days,' / ',signif(yrmodat$avg_unmet,digits=1), sep=''),
                    x=yrmodat$month, y= yrmodat$year), size = 3, colour = "black") +
      scale_fill_gradient2(low = "#00cc00", high = "red",mid ='yellow',
                           midpoint = 15, guide = "colourbar",
                           name= 'Unmet Days') +
      theme(panel.background = element_rect(fill = "transparent"))+
      theme() + labs(title = 'Unmet Demand Heatmap', y=NULL, x=NULL) +
      scale_x_continuous(expand=c(0,0), breaks= x_breaks, labels=x_labs, position='top') +
      scale_y_reverse(expand=c(0,0), breaks=y_breaks, labels= y_labs) +
      theme(axis.ticks= element_blank()) +
      theme(plot.title = element_text(size = 12, face = "bold",  hjust = 0.5)) +
      theme(legend.title.align = 0.5)
    
    unmet <- count_grid + new_scale_fill() +
      geom_tile(data = yesum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_tile(data = mosum, color='black', aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = yesum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      geom_text(data = mosum, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days)) +
      scale_fill_gradient2(low = "#63D1F4", high = "#8A2BE2", mid='#CAB8FF',
                           midpoint = mean(mosum$count_unmet_days), name= 'Total Unmet Days')
    
    total <- unmet + new_scale_fill() +
      geom_tile(data = total_unmet_days_cell, color='black',fill="grey",aes(x = month, y = year, fill = count_unmet_days)) +
      geom_text(data = total_unmet_days_cell, size = 3.5, color='black', aes(x = month, y = year, label = count_unmet_days))
    
    #unmet_avg <- unmet + new_scale_fill()+
    unmet_avg <- total + new_scale_fill()+ 
      geom_tile(data = yeavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_tile(data = moavg, color='black', aes(x = month, y = year, fill = avg)) +
      geom_text(data = yeavg, size = 3.5, color='black', aes(x = month, y = year, label = avg)) +
      geom_text(data = moavg, size = 3.5, color='black', aes(x = month, y = year, label = avg))+
      scale_fill_gradient2(low = "#FFF8DC", mid = "#FFDEAD", high ="#DEB887",
                           name= 'Average Unmet Days', midpoint = mean(yeavg$avg))
    
  }
  
  fname3 <- paste(save_directory,paste0('fig.unmet_heatmap_amt_gw.',elid,'.',runid ,'.png'),sep = '/')
  
  # furl3 <- paste(save_url, paste0('fig.unmet_heatmap_amt.',elid, '.', runid, '.png'),sep = '/')
  
  ggsave(fname3,plot = unmet_avg, width= 9.5, height=6)
  
  print('File saved to save_directory')

} #close for loop
