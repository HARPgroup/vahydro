##################################################################################
# ODBC
##################################################################################
# load R odbc package
library(odbc)

# establish database connection
con <- odbc::dbConnect(odbc::odbc(),
                       driver = "ODBC Driver 18 for SQL Server",
                       server = "DEQ-SQL-TEST,50000",
                       database = "ODS",
                       trusted_connection = "yes",
                       TrustServerCertificate = "yes")
show(con)

# inspect objects within ODS catalog, water schema
# note: looks like we've only been granted access to one of these views at this time
odbc::odbcListObjects(con, catalog="ODS", schema="water")

# example retrieving a large view from ODS (38k rows, 64 columns)
start_time <- Sys.time()
Wp_Water_Permits_VW_View <- odbc::dbGetQuery(con,  "SELECT * FROM water.Wp_Water_Permits_VW_View")
end_time <- Sys.time()
print(round((end_time - start_time),3))

# filtering your query prior to retrieval, speeds up retrieval time
# alternatively, you can retrieve an entire view and then filter using sqldf
query <- "SELECT * 
          FROM water.Wp_Water_Permits_VW_View
          WHERE OFFICE = 'CO'"

# retrieve your query result as dataframe
mydf <- odbc::dbGetQuery(con, query)

##################################################################################
# POOL
##################################################################################
# you can use the pool package the same way as odbc
# pool has benefits for things such as shiny apps

library(pool)
library(dplyr)
library(dbplyr)
library(tibble)

pool <- pool::dbPool(
  drv = odbc::odbc(),
  Driver = "ODBC Driver 18 for SQL Server",
  Server= "DEQ-SQL-TEST,50000",
  dbname = "ODS",
  trusted_connection = "yes",
  TrustServerCertificate = "yes"
)

query <- "SELECT * 
          FROM water.Wp_Water_Permits_VW_View
          WHERE OFFICE = 'CO'"
mydf <- odbc::dbGetQuery(pool, query)

Wp_Water_Permits_VW_View <- pool %>% dplyr::tbl(dbplyr::in_schema("water",  "Wp_Water_Permits_VW_View")) %>% tibble::as_tibble()
