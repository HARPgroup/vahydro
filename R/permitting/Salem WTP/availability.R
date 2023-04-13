library("knitr")
library("kableExtra")
library("hydrotools")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/om_cu_table.R")
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
sh_dat$Qmgd <- sh_dat$Qintake / 1.547
shav <- om_flow_table(sh_dat, 'available_mgd')
fqcu_table <- om_cu_table(
  list(), sh_dat, 
  'available_mgd', 'Qmgd', 
  c(0,15,25), 2
) 
om_flow_table(sh_dat, q_col = 'available_mgd', mo_col = "month", rdigits = 2)
rmarkdown::render('/usr/local/home/git/vahydro/R/OWS_summaries/imp_yield.Rmd', output_file = '/WorkSpace/modeling/projects/roanoke/salem/salem_cia.docx', params = list( doc_title = 'Scenario Detail – Salem', model_feature = 68327, model_pid = 4713208, scenario = "runid_222", model_version= "vahydro-1.0", image_names =c("fig.unmet_heatmap_amt", "fig.monthly_demand" ), column_descriptions =c("Unmet Demand", "Monthly Demand" )))