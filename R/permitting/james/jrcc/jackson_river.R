# Load base info in jrcc.R

# Find river seg facilities: JU3_6950_7330  
sqldf("select * from fac_data where riverseg = 'JU3_6950_7330'")
# Find river seg facilities: JU3_6950_7330  
sqldf("select * from wshed_case where riverseg = 'JU3_6950_7330'")
sqldf("select * from fac_data where riverseg = 'JU3_6380_6900'")
sqldf("select * from wshed_case where riverseg = 'JU3_6380_6900'")

jack400u <- om_get_rundata(210265, 400, site = omsite)
jack400ro <- om_get_rundata(211191, 400, site = omsite)

datjack400 <- om_get_rundata(214595, 400, site = omsite)
datjack600 <- om_get_rundata(214595, 600, site = omsite)
cov400 <- om_get_rundata(320768, 400, site = omsite)
cov600 <- om_get_rundata(320768, 600, site = omsite)