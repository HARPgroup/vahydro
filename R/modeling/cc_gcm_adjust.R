# save coefficeint data on p6 segments
# one file for each GCM scenario in these directories:
# - Temp: https://github.com/HARPgroup/cbp6/tree/master/daniel's%20thesis%20scripts/GCM%20Temperature%20Data
# - Precip: https://github.com/HARPgroup/cbp6/tree/master/daniel's%20thesis%20scripts/GCM%20Precipitation%20Data

# load directory contents
# iterate through files
# - load landseg
# - load/create landseg model "ccP10T10" (or ccP50T50,ccP90T90), propcode=rcp_45
# - load/create container landseg/gcm_models
# - load/create landseg/gcm_models/[gcm model name]# 
# - load/create property ccP10T10/delta_1990 (pointer to the 10th,50th,90th percentile)


default_p_fact <- c()
default_t_fact <- c() 

