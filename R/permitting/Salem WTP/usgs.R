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


# north and south Roanoke Confluence, old met
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/Salem WTP/OR2_7900_7740_02054530.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 249169,
    runid = 222,
    area_factor = 379.95 / 281.0,
    gageid = '02054530'))


# north and south Roanoke Confluence, new met
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/OR2_8020_8130_02053800-newmet.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 251597,
    runid = 200,
    area_factor = 1.0,
    gageid = '02053800'))


# Wayside park
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/Salem WTP/OR2_8130_7900_02054530-newmet.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 251491,
    runid = 222,
    area_factor = 1.0,
    gageid = '02054530',
    summary_text = 'The following plots provide a comparison of VAHydro model performance for the model segment above the Salem WTP (Roanoke River (Wayside Park)) compared against historic streamflow recorded that USGS 02054530 ROANOKE RIVER AT GLENVAR, VA. This analysis provides additional context to overall model performance.'
  )
)
