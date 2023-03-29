library("knitr")
library("kableExtra")
library()

basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#source("/var/www/R/config.local.private");
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

ccelid = 328319
cc_dat <- om_get_rundata(ccelid , 222, site = omsite)
cc_dat$qcu <- ( cc_dat$impoundment_Qin - cc_dat$impoundment_Qout )
wd_r4 = om_flow_table(cc_dat, 'qcu')
om_flow_table(cc_dat, 'avail_catawba')
om_flow_table(cc_dat, 'qcu')
atc <- om_flow_table(cc_dat, 'avail_tinker')
kable(atc)

selid = 306768
s_dat <- om_get_rundata(selid , 222, site = omsite)
sav <- om_flow_table(cc_dat, 'available_mgd')


shelid = 328321
sh_dat <- om_get_rundata(shelid , 222, site = omsite)
shav <- om_flow_table(sh_dat, 'available_mgd')
