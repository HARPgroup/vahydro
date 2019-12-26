################################
#### *** Water Supply Element
################################
# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279187, South Anna - 207771
elid = 229875    
runid = 22

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(ps_mgd) as ps_mgd from datdf group by month")
mot <- t(as.matrix(modat[,c('ps_mgd')]) )
mode(mot) <- 'numeric'
barplot(
  mot,
  main="Monthly Mean Return Flows",
  xlab="Month", 
  col=c("darkgreen"),
  legend = c('Discharge'), beside=TRUE
)

