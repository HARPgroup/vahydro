#!/bin/bash

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: vahydro_calib_models.sh riverseg gageid cbp_version [p532cal_062211, CFBASE30Y20180615, ...]"
  exit 2
fi 
riverseg=$1
gageid=$2
cbp_version="CFBASE30Y20180615"
if [ $# -gt 2 ]; then
  cbp_version=$3
fi 

cd /var/www/R

Rscript /opt/model/om/R/summarize/model-streamgage-comparison.R $riverseg 11 $gageid $cbp_version
Rscript /opt/model/om/R/summarize/model-streamgage-comparison.R $riverseg 11 $gageid vahydro-1.0
