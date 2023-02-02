basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library('dataRetrieval')

gage_number = '01633000'
startdate = '1900-01-01'
enddate = '2022-12-31'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
om_flow_table(gage_data, 'flow')

available_mgd <- gage_data
available_mgd$available_mgd <- (available_mgd$flow * 0.2) / 1.547
avail_table = om_flow_table(available_mgd, 'available_mgd')
kable(avail_table, 'markdown')

rmarkdown::render(
'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
output_file = '/usr/local/home/git/vahydro/R/permitting/broadway/PS2_5560_5100_01633000.docx',
params = list(
doc_title = "USGS Gage vs VAHydro Model",
elid = 229937,
runid = 11,
gageid = '01633000'
)
)

# north and south Roanoke Confluence, old met
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/OR2_8020_8130_02053800.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 251597,
    runid = 600,
    gageid = '02053800'))


# north and south Roanoke Confluence, new met
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/OR2_8020_8130_02053800-newmet.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 251597,
    runid = 222,
    gageid = '02053800'))


