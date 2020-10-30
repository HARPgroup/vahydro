#!/bin/bash

if [ $# -lt 2 ]; then
  echo 1>&2 "Usage: vahydro_calib_models.sh riverseg gageid "
  exit 2
fi 
riverseg=$1
gageid=$2

cd /var/www/R

Rscript /opt/model/om/R/summarize/model-streamgage-comparison.R $riverseg 11 $gageid CFBASE30Y20180615
Rscript /opt/model/om/R/summarize/model-streamgage-comparison.R $riverseg 11 $gageid vahydro-1.0
