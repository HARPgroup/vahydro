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

# see slides showing T and P quantiles for whole cbp
default_p10_fact <- c(-7.61,-1.62,-7.61,-5.05,-5.01,-14.21,-12.57,-13.84,-14.67,-17.69,-9.01,-8.64)
default_t10_fact <- c(0.81,0.83,1.12,1.18,1.07,1.21,1.36,1.33,1.65,1.07,1.32,0.89) 
default_p90_fact <- c(20.94,27.71,20.96,24.89,19.40,19.48,21.31,20.64,17.84,20.84,19.27,25.35)
default_t90_fact <- c(3.23,3.37,3.07,3.09,2.62,2.71,3.29,3.28,3.59,2.84,3.02,3.16) 


