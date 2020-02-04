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


#aggregate by county AND ftype
gwma <- sqldf("
  SELECT facility_ftype,
    sum(mp_2020_mgy) as mp_2020_mgy,
    sum(mp_2020_mgy)/365.25 as mp_2020_mgd,
    sum(mp_2040_mgy) as mp_2040_mgy,
    sum(mp_2040_mgy)/365.25 as mp_2040_mgd
  FROM MP
  WHERE fips_code in (51001, 51033, 51036, 51550, 51041, 51057, 51059, 51620, 51073, 51650, 51085, 51087, 51670, 51093, 51095, 51097, 51099, 51101, 51103, 51115, 51119, 51127, 51700, 51131, 51133, 51735, 51740, 51149, 51153, 51159, 51175, 51177, 51179, 51800, 51181, 51183, 51810, 51193, 51830, 51199)
                     AND
                     ftype NOT LIKE '%power'
  GROUP BY facility_ftype
")
nongwma <- sqldf("
  SELECT facility_ftype,
    sum(mp_2020_mgy) as mp_2020_mgy,
    sum(mp_2020_mgy)/365.25 as mp_2020_mgd,
    sum(mp_2040_mgy) as mp_2040_mgy,
    sum(mp_2040_mgy)/365.25 as mp_2040_mgd
  FROM MP
  WHERE fips_code NOT in (51001, 51033, 51036, 51550, 51041, 51057, 51059, 51620, 51073, 51650, 51085, 51087, 51670, 51093, 51095, 51097, 51099, 51101, 51103, 51115, 51119, 51127, 51700, 51131, 51133, 51735, 51740, 51149, 51153, 51159, 51175, 51177, 51179, 51800, 51181, 51183, 51810, 51193, 51830, 51199)
                     AND
                     ftype NOT LIKE '%power'
  GROUP BY facility_ftype
")

gwma_total <- sqldf("
  select sum(mp_2020_mgd) as gwma2020_mgd,
    sum(mp_2040_mgd) as gwma2040_mgd
  from gwma
")

nongwma_total <- sqldf("
  select sum(mp_2020_mgd) as gwma2020_mgd,
    sum(mp_2040_mgd) as gwma2040_mgd
  from nongwma
")