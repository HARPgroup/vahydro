#STATE PLAN SUMMARIES

########################################################################################
require(sqldf)
#require(rgdal)
require(httr)

#----------------------------------------------
# USER INPUTS

basepath <- 'http://deq2.bse.vt.edu/d.dh/'
y = 2018

export_date <- Sys.Date()
export_path <- "U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\"
#----------------------------------------------

#prevents scientific notation
options(scipen = 20)

#read in foundational MP-level dataset
MP <- read.csv(file = paste0(export_path,'wsp2020.mp.all.csv',sep='' ))

#aggregate by county (fips_code) and sum the 2020, 2040 demand projections
grouped_by_county <- sqldf("SELECT fips_code, sum(mp_2020_mgy) as mp_2020_mgy, sum(mp_2020_mgy)/365.25 as mp_2020_mgd, sum(mp_2040_mgy) as mp_2040_mgy, sum(mp_2040_mgy)/365.25 as mp_2040_mgd
                           FROM MP
                           GROUP BY fips_code
                           ")
#add 2 new columns that show demand projection change in mgy and percentage 
grouped_by_county$delta_2040_mgy <- (grouped_by_county$mp_2040_mgy - grouped_by_county$mp_2020_mgy)
grouped_by_county$delta_2040_pct <- ((grouped_by_county$mp_2040_mgy - grouped_by_county$mp_2020_mgy) / grouped_by_county$mp_2040_mgy)*100

#change the fips code to see all MPs (wells) in that county
specify_county <- sqldf("SELECT *
                         FROM MP
                         WHERE fips_code = '51840'")

#aggregate by county AND ftype
grouped_by_county_ftype <- sqldf("SELECT fips_code, facility_ftype, sum(mp_2020_mgy) as mp_2020_mgy, sum(mp_2020_mgy)/365.25 as mp_2020_mgd, sum(mp_2040_mgy) as mp_2040_mgy, sum(mp_2040_mgy)/365.25 as mp_2040_mgd
                           FROM MP
                           GROUP BY fips_code, facility_ftype
                           ")

#change facility_ftype to be the category you want to see
specify_ftype <- sqldf("SELECT fips_code, facility_ftype, sum(mp_2020_mgy) as mp_2020_mgy, sum(mp_2020_mgy)/365.25 as mp_2020_mgd, sum(mp_2040_mgy) as mp_2040_mgy, sum(mp_2040_mgy)/365.25 as mp_2040_mgd
                           FROM MP
                           WHERE facility_ftype = 'mining'
                           GROUP BY fips_code, facility_ftype
                           ")
