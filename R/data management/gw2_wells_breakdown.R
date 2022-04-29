#Breakdown of GW2 wells by Facility Use Type and Well Type
library(sqldf)

#Download export file from "Export All Wells" VAHydro page: https://deq1.bse.vt.edu/d.dh/ows-well-export?bundle%5B%5D=well&fstatus_1=&permit_id_value=&name=&fstatus_2_op=in&ftype=&ftype_1_op=contains&ftype_1=&address1_value_op=%3D&address1_value=&address2_value_op=%3D&address2_value=&name_1_op=contains&name_1=

#Export csv url: https://deq1.bse.vt.edu/d.dh/ows-all-mp-data-export?bundle%5B0%5D=well&fstatus_1=&permit_id_value=&name=&fstatus_2_op=in&ftype=&ftype_1_op=contains&ftype_1=&address1_value_op=%3D&address1_value=&address2_value_op=%3D&address2_value=&name_1_op=contains&name_1=
aa <- read.csv("C:/Users/maf95834/Downloads/ows_well_export (5).csv", header = T)

a <- sqldf('SELECT *
           FROM a
           WHERE "Use.Type" NOT IN ("drought_region", "wsp_plan_system-ssulg", "wsp_plan_system-cws", "wsp_plan_system-ssuag", "wsp_plan_system-ssusm", "facility")') 

gw2_only <- sqldf('SELECT *
           FROM a
           WHERE "Use.Type" LIKE "gw2_%"') 
#write.csv(gw2_only, "C:/Users/maf95834/Downloads/gw2_wells_4-28-2022.csv", row.names = F)
names(a)

facility_usetype <- sqldf('SELECT DISTINCT "Use.Type" 
      FROM a')

welltype <- sqldf('SELECT DISTINCT "Well.Type" 
      FROM a')

gw2_total <- sqldf('SELECT count("Use.Type") 
           FROM a
           WHERE "Use.Type" LIKE "gw2_%"') 

gw2 <- sqldf('SELECT count(MP_HydroID), "Use.Type"
           FROM a
           WHERE "Use.Type" LIKE "gw2_%"
           GROUP BY "Use.Type"') 

gw2_waterworks <- sqldf('SELECT count(MP_HydroID), "Well.Type", "Use.Type"
           FROM a
           WHERE "Use.Type" LIKE "gw2_municipal"
           GROUP BY "Well.Type", "Use.Type"') 
gw2_private <- sqldf('SELECT count(MP_HydroID), "Well.Type", "Use.Type"
           FROM a
           WHERE "Use.Type" LIKE "gw2_private"
           GROUP BY "Well.Type", "Use.Type"') 
gw2_monitoring <- sqldf('SELECT count(MP_HydroID), "Well.Type", "Use.Type"
           FROM a
           WHERE "Use.Type" LIKE "gw2_monitoring"
           GROUP BY "Well.Type", "Use.Type"') 
