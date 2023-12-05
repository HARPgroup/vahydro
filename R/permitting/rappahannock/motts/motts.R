library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Motts fac
mfelid = 322005
datmf401 <- om_get_rundata(mfelid, 401, site = omsite)

# river
rapelid = 258123 # Rapidan
datrap <- om_get_rundata(rapelid, 400, site = omsite)
rpid = 6605616
hrelid = 352159
mrelid = 352157
dathr401 <- om_get_rundata(hrelid, 401, site = omsite)
datmr401 <- om_get_rundata(mrelid, 401, site = omsite)
quantile(datmr401$wd_hr_mgd)
quantile(datmr401$wd_mr_mgd)
quantile(datmr401$wd_hr_mgd + datmr401$wd_mr_mgd)
quantile(datmr401$child_wd_mgd)
quantile(datmr401$system_urm)
