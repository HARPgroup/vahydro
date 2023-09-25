# import libraries
import pandas as pd
import duckdb
from reportlab.lib.units import inch
from reportlab.lib.pagesizes import letter, landscape, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, PageBreak, Frame, PageTemplate
from reportlab.platypus.doctemplate import NextPageTemplate
from reportlab.platypus.tables import Table,TableStyle,colors
from reportlab.lib.styles import getSampleStyleSheet
from datetime import date

# specify filepaths
# export_path = "C:/Users/nrf46657/Desktop/GitHub/vahydro/drupal/dh_drought/src/python/"
export_path = "/var/www/html/drought/state/deq_daily_drought_summaries/"
drought_summary_map_file = "https://deq1.bse.vt.edu/drought/state/images/maps/virginia_drought.png"
drought_indicator_map_file = "https://deq1.bse.vt.edu/drought/state/images/maps/virginia_drought_indicators.png"

# define dataset sources
baseurl = 'https://deq1.bse.vt.edu/d.dh'
response_source = 'regional-drought-response-export'
precip_source = 'precipitation-drought-timeseries-export'
sw_source = 'streamflow-drought-timeseries-all-export'
gw_source = 'groundwater-drought-timeseries-all-export'
res_source = 'reservoir-drought-features-export'

# get data from a vahydro views export
def get_data_vahydro(viewurl, baseurl = baseurl):
    url = baseurl + "/" + viewurl
    df=pd.read_csv(url)
    return df

# add row number to list in order to display number column in table
def add_rownum_to_nested_list(data_list):
    data_list_WithRowNums = []
    for i in range(len(data_list)):
        data_list_unnested = data_list[i]
        data_list_unnested.insert(0, i+1)
        data_list_WithRowNums.append(data_list_unnested)
    return(data_list_WithRowNums)

# retrieve regional response data
response_df = get_data_vahydro(viewurl = response_source)
# process regional response data
response_df = duckdb.sql("""
                       SELECT drought_region AS region, 
                            propcode,
                            proptext
                       FROM response_df
                       ORDER BY proptext ASC
                       """).df()
response_pd = pd.DataFrame(response_df)


# retrieve precip indicator data
precip_df = get_data_vahydro(viewurl = precip_source)
# process precip indicator data
precip_df = duckdb.sql("""
                       SELECT drought_region AS region, 
                            startdate,
                            enddate,
                            Water_Year_pct_of_Normal_propvalue AS 'water yr % of normal',
                            CASE
                                WHEN Drought_Status_propcode = 0 THEN 'Normal'
                                WHEN Drought_Status_propcode = 1 THEN 'Watch'
                                WHEN Drought_Status_propcode = 2 THEN 'Warning'
                                WHEN Drought_Status_propcode = 3 THEN 'Emergency'
                            END AS status
                        FROM precip_df
                        ORDER BY status DESC, Water_Year_pct_of_Normal_propvalue ASC
                       """).df()
precip_pd = pd.DataFrame(precip_df)

# retrieve surface water indicator data
sw_df = get_data_vahydro(viewurl = sw_source)
# reutrn only the 11 official drought evaluation region stream gage indicators
sw_official_df = sw_df[pd.notna(sw_df)['drought_evaluation_region'] == True]
# process surface water indicator data
sw_status_df = duckdb.sql("""
                          SELECT drought_evaluation_region AS region, 
                                gage_name,
                                q_7day_cfs_tstime AS tstime, 
                                q_7day_cfs_tsendtime AS tsendtime, 
                                nonex_pct_propvalue AS 'percentile',
                                CASE
                                    WHEN nonex_pct_propcode = 0 THEN 'Normal'
                                    WHEN nonex_pct_propcode = 1 THEN 'Watch'
                                    WHEN nonex_pct_propcode = 2 THEN 'Warning'
                                    WHEN nonex_pct_propcode = 3 THEN 'Emergency'
                                END AS status
                          FROM sw_official_df
                          ORDER BY nonex_pct_propvalue ASC
                          """).df()
sw_pd = pd.DataFrame(sw_status_df)

# retrieve groundwater indicator data
gw_df = get_data_vahydro(viewurl = gw_source)
# process groundwater indicator data
gw_max_status_df = duckdb.sql("""
                              SELECT drought_evaluation_region AS region,
                                    well_name, 
                                    gwl_7day_ft_tstime AS tstime, 
                                    gwl_7day_ft_tsendtime AS tsendtime, 
                                    nonex_pct_propvalue AS 'percentile',
                                    CASE
                                        WHEN nonex_pct_propcode = 0 THEN 'Normal'
                                        WHEN nonex_pct_propcode = 1 THEN 'Watch'
                                        WHEN nonex_pct_propcode = 2 THEN 'Warning'
                                        WHEN nonex_pct_propcode = 3 THEN 'Emergency'
                                    END AS max_status
                              FROM gw_df
                              ORDER BY nonex_pct_propcode DESC, drought_evaluation_region ASC
                              """).df()
gw_pd = pd.DataFrame(gw_max_status_df)

# retrieve reservoir indicator data
res_df = get_data_vahydro(viewurl = res_source)
# process reservoir indicator data
res_status_df = duckdb.sql("""
                           SELECT drought_region AS region,
                                reservoir_name,
                                startdate,
                                CASE
                                    WHEN Drought_Status_propcode = 0 THEN 'Normal'
                                    WHEN Drought_Status_propcode = 1 THEN 'Watch'
                                    WHEN Drought_Status_propcode = 2 THEN 'Warning'
                                    WHEN Drought_Status_propcode = 3 THEN 'Emergency'
                                END AS status
                           FROM res_df
                           ORDER BY status DESC, drought_region ASC
                           """).df()
# note, resevoir status is not automated, defaulting date to current day for now
res_status_df['startdate'] = date.today().strftime('%m/%d/%Y')
res_pd = pd.DataFrame(res_status_df)

###############################################################
# format data for pdf output
###############################################################
output_filename = "DEQ_Daily_Drought_Summary_{}.pdf".format(date.today().strftime('%Y.%m.%d'))

my_doc = SimpleDocTemplate(export_path + output_filename, pagesize=letter, title=output_filename, author="DEQ")
portrait_frame = Frame(my_doc.leftMargin, my_doc.bottomMargin, my_doc.width, my_doc.height, id='portrait_frame ')
landscape_frame = Frame(my_doc.leftMargin, my_doc.bottomMargin, my_doc.height, my_doc.width, id='landscape_frame ')
styles = getSampleStyleSheet()

c_width=[0.4*inch,2.0*inch,1*inch,1*inch,1*inch,0.7*inch,0.7*inch] # width of the columns 

response_data=response_pd.values.tolist() # create a list using Dataframe
response_data=add_rownum_to_nested_list(response_data)
response_colnames = [['#', 'Region', 'Reduction Type', 'Target Reduction %']]
response_data = response_colnames + response_data
response_t=Table(response_data,colWidths=[0.4*inch,2.0*inch,1.8*inch,1.8*inch],repeatRows=1)
response_t.setStyle(TableStyle([('FONTSIZE',(0,0),(-1,-1),12),('BACKGROUND',(0,0),(-1,0),colors.lightgrey),('VALIGN',(0,0),(-1,0),'TOP')]))

precip_data=precip_pd.values.tolist() # create a list using Dataframe
precip_data=add_rownum_to_nested_list(precip_data)
precip_colnames = [['#', 'Region', 'Start Date', 'End Date', 'Water Year\n% of Normal', 'Status']]
precip_data = precip_colnames + precip_data
precip_t=Table(precip_data,colWidths=c_width,repeatRows=1)
precip_t.setStyle(TableStyle([('FONTSIZE',(0,0),(-1,-1),12),('BACKGROUND',(0,0),(-1,0),colors.lightgrey),('VALIGN',(0,0),(-1,0),'TOP')]))

sw_data=sw_pd.values.tolist() # create a list using Dataframe
sw_data=add_rownum_to_nested_list(sw_data)
colnames = [['#','Region', 'Gage Name', 'Start Date', 'End Date', 'Percentile', 'Status']]
c_width=[0.4*inch,1.8*inch,4.85*inch,1*inch,1*inch,1*inch,0.7*inch,0.7*inch] 
sw_data = colnames + sw_data
sw_t=Table(sw_data,colWidths=c_width,repeatRows=1)
sw_t.setStyle(TableStyle([('FONTSIZE',(0,0),(-1,-1),12),('BACKGROUND',(0,0),(-1,0),colors.lightgrey),('VALIGN',(0,0),(-1,0),'TOP')]))

gw_data=gw_pd.values.tolist() # create a list using Dataframe
gw_data=add_rownum_to_nested_list(gw_data)
colnames = [['#','Region', 'Well Name', 'Start Date', 'End Date', 'Percentile', 'Status']]
c_width=[0.4*inch,1.8*inch,4.85*inch,1*inch,1*inch,1*inch,0.7*inch,0.7*inch] 
gw_data = colnames + gw_data
gw_t=Table(gw_data,colWidths=c_width)
gw_t.setStyle(TableStyle([('FONTSIZE',(0,0),(-1,-1),12),('BACKGROUND',(0,0),(-1,0),colors.lightgrey),('VALIGN',(0,0),(-1,0),'TOP')]))

res_data=res_pd.values.tolist() # create a list using Dataframe
res_data=add_rownum_to_nested_list(res_data)
res_colnames = [['#', 'Region', 'Reservoir', 'Date', 'Status']]
c_width_res=[0.4*inch,1.8*inch,2.8*inch,1*inch,1*inch,0.7*inch] # width of the columns 
res_data = res_colnames + res_data
res_t=Table(res_data,colWidths=c_width_res,repeatRows=1)
res_t.setStyle(TableStyle([('FONTSIZE',(0,0),(-1,-1),12),('BACKGROUND',(0,0),(-1,0),colors.lightgrey),('VALIGN',(0,0),(-1,0),'TOP')]))

elements=[]
today = date.today()
today = today.strftime('%m/%d/%Y')
title = "DEQ Daily Drought Status Summary: {}".format(today)
elements.append(Spacer(1,-0.6*inch)) # shift title upwards
elements.append(Paragraph(title, styles['Title']))

elements.append(Spacer(1,0.2*inch))
map_text = Paragraph("Drought Summary Map:", styles['Heading3'])
elements.append(map_text)
elements.append(Spacer(1,-0.05*inch))
map_img = Image(drought_summary_map_file, 6.25*inch, 3.75*inch)
elements.append(map_img)

elements.append(Spacer(1,-0.7*inch))
indicator_map_text = Paragraph("Drought Indicator Map:", styles['Heading3'])
elements.append(indicator_map_text)
map_img_indicators = Image(drought_indicator_map_file, 6.40*inch, 4.87*inch)
elements.append(map_img_indicators)

response_text = Paragraph("Regional Drought Response:", styles['Heading3'])
elements.append(response_text)
elements.append(response_t)

elements.append(Spacer(1,0.2*inch))
precip_text = Paragraph("Precipitation Indicators:", styles['Heading3'])
elements.append(precip_text)
elements.append(precip_t)

elements.append(NextPageTemplate('landscape'))
elements.append(PageBreak())
sw_text = Paragraph("Surface Water Indicators:", styles['Heading3'])
elements.append(sw_text)
elements.append(sw_t)

elements.append(NextPageTemplate('landscape'))
elements.append(PageBreak())
elements.append(Spacer(1,-0.4*inch))
gw_text = Paragraph("Groundwater Indicators:", styles['Heading3'])
elements.append(gw_text)
elements.append(gw_t)

elements.append(PageBreak())
res_text = Paragraph("Reservoir Indicators:", styles['Heading3'])
elements.append(res_text)
elements.append(Paragraph("Note, these reservoir statuses require manual review as they are NOT automated at this time", styles['Heading4']))
elements.append(res_t)

my_doc.addPageTemplates([PageTemplate(id='portrait',frames=portrait_frame),
                      PageTemplate(id='landscape',frames=landscape_frame, pagesize=landscape(A4)),
                      ])
my_doc.build(elements)

print("Document Generated: " + today)
