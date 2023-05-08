library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 249169 # Roanoke River (Salem)
fac_om_id <- 306768 # Salem WTP:Roanoke River (Salem)
# runid <- 222
# runid <- 600
runid <- 400
################################################################################################
################################################################################################

rseg_dat <- om_get_rundata(rseg_om_id, runid, site = omsite)
fac_dat <- om_get_rundata(fac_om_id, runid, site = omsite)

rseg_dat_df <- data.frame(rseg_dat)
fac_dat_df <- data.frame(fac_dat)

# sort(colnames(rseg_dat_df))
# sort(colnames(fac_dat_df))

rseg_dat_df <- sqldf("SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS 'index', * FROM 'rseg_dat_df'")
fac_dat_df <- sqldf("SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS 'index', * FROM 'fac_dat_df'")
################################################################################################
################################################################################################
# qa <- sqldf("SELECT fac.year,fac.month,fac.day, 
#             fac.Qintake AS fac_Qintake, 
#             fac.Qriver AS fac_Qriver, 
#             fac.Qriver_up AS fac_Qriver_up,
#             rseg.Qout AS rseg_Qout,
#             rseg.Qup AS rseg_Qup
#             FROM fac_dat_df AS fac
#             LEFT OUTER JOIN 'rseg_dat_df' AS rseg
#             ON fac.'index' = rseg.'index'
#             ")
qa <- sqldf("SELECT fac.year,fac.month,fac.day, 
            fac.Qintake AS fac_Qintake, 
            fac.Qriver_up AS fac_Qriver_up,
            rseg.Qout AS rseg_Qout,
            rseg.Qup AS rseg_Qup
            FROM fac_dat_df AS fac
            LEFT OUTER JOIN 'rseg_dat_df' AS rseg
            ON fac.'index' = rseg.'index'
            ")
################################################################################################
################################################################################################
sort(colnames(fac_dat_df))

quantile(fac_dat_df$flowby)






