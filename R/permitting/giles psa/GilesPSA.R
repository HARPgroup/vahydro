library(sqldf)

datasite <- "http://deq1.bse.vt.edu/d.dh"
export_view <- paste0("ows-awrr-map-export-batch/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=2010-01-01&tstime%5Bmax%5D=2022-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake&hydroid=72813")

giles_df <- read.table(file = paste(datasite,export_view,sep="/"), header = TRUE, sep = ",")


##################################################################
fac_totals <- sqldf(paste('SELECT facility_name, Year, SUM(`Water.Use.MGY`) AS annual_total_mgy
                    FROM giles_df
                    GROUP BY Year
                    ORDER BY Year',sep="")) 
##################################################################

##################################################################
# COMPUTE 5-Year AVG
fac_five_yr <-sqldf(paste('SELECT *, AVG(`annual_total_mgy`)
                                OVER (ORDER BY Year ASC
                                  ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS five_yr_avg
                    FROM fac_totals
                    ORDER BY Year',sep="")) 
##################################################################