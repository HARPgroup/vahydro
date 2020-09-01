

mp_layer  <- mp.all 
runid_b <- "runid_18"

# #REMOVE POWER
mp_layer_nohydro <- paste("SELECT *
                  FROM mp_layer
                  WHERE facility_ftype NOT LIKE '%power%'")
#WHERE facility_ftype != 'hydropower'")
mp_layer <- sqldf(mp_layer_nohydro)

mp_layer$mp_exempt_mgy <- mp_layer$final_exempt_propvalue_mgd*365.25
demand_query_param <-case_when(runid_b == "runid_12" ~ "mp_2030_mgy",
                               runid_b == "runid_13" ~ "mp_2040_mgy",
                               runid_b == "runid_14" ~ "mp_2020_mgy",
                               runid_b == "runid_15" ~ "mp_2020_mgy",
                               runid_b == "runid_16" ~ "mp_2020_mgy",
                               runid_b == "runid_17" ~ "mp_2040_mgy",
                               runid_b == "runid_18" ~ "mp_exempt_mgy",
                               runid_b == "runid_19" ~ "mp_2040_mgy",
                               runid_b == "runid_20" ~ "mp_2040_mgy")

#mp_layer_sql <- paste('SELECT *, round(',demand_query_param,'/365.25,3) AS demand_metric
mp_layer_sql <- paste('SELECT *, ',demand_query_param,'/365.25 AS demand_metric
                         FROM mp_layer'
                      ,sep="")
mp_layer <- sqldf(mp_layer_sql)


#DIVISIONS IN MGD
div <- c(0.5,1.0,2.0,5.0,10,25,50,100,1000)

bins_sql <-  paste("SELECT *,
	                  CASE WHEN demand_metric <= ",div[1]," THEN '1'
		                WHEN demand_metric >  ",div[1]," AND demand_metric <= ",div[2]," THEN '2'
		                WHEN demand_metric >  ",div[2]," AND demand_metric <= ",div[3]," THEN '3'
		                WHEN demand_metric >  ",div[3]," AND demand_metric <= ",div[4]," THEN '4'
		                WHEN demand_metric >  ",div[4]," AND demand_metric <= ",div[5]," THEN '5'
		                WHEN demand_metric > ",div[5]," AND demand_metric <= ",div[6]," THEN '6'
		                WHEN demand_metric > ",div[6]," AND demand_metric <= ",div[7]," THEN '7'
		                WHEN demand_metric > ",div[7]," AND demand_metric <= ",div[8]," THEN '8'
		                WHEN demand_metric > ",div[8]," AND demand_metric <= ",div[9]," THEN '9'
		                WHEN demand_metric > ",div[9]," THEN '10'
		                ELSE 'X'
		                END AS bin
		                FROM mp_layer",sep="")
mp_layer <- sqldf(bins_sql)