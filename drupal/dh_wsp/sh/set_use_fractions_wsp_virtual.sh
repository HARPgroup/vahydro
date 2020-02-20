#!/bin/bash

if [ "$1" == "--help" ]; then
  echo 1>&2 "Usage: set_use_fractions_wsp_virtual.sh [facility ydroid] "
  exit 2
fi 

frac_query=`cat modules/dh_wsp/sql/create_use_fractions_wsp_virtual.sql`

# County Virtual Well and Intakes 
frac_query = "$frac_query 
  select 'dh_feature' as entity_type, vmp.hydroid as featureid, 
  'facility_use_fraction' as varkey, 
  'facility_use_fraction' as propname,
  CASE 
    WHEN vmp.bundle = 'intake' THEN vfac.sw_frac 
    WHEN vmp.bundle = 'well' THEN vfac.gw_frac 
    ELSE 0.0
  END as propvalue
  from tmp_wsp_virtual_fracs as vfac 
  left outer join field_data_dh_link_facility_mps as mplink
  on (
    mplink.dh_link_facility_mps_target_id = vfac.hydroid 
  )
  left outer join dh_feature as vmp  
  on (
    mplink.entity_id = vmp.hydroid 
  )"
if [ $# -gt 0 ]; then
  hydroid=$1
  frac_query="$frac_query WHERE vfac.hydroid = $hydroid"
fi 
  
echo $frac_query | PGOPTIONS='--client-min-messages=warning' psql -h dbase2 drupal.dh03 > /tmp/virtual_use_fractions.txt 



n=`< /tmp/virtual_use_fractions.txt wc -l`
nm="$((n - 2))"
head -n $nm /tmp/virtual_use_fractions.txt > /tmp/fhead.txt 
n=`< /tmp/fhead.txt wc -l`
nm="$((n - 4))"
tail -n $nm /tmp/fhead.txt > /tmp/virtual_use_fractions.txt 

while IFS= read -r line; do
  #echo "Text read from file: $line"
  IFS="$IFS|" read entity_type featureid varkey propname propvalue <<< "$line"
  drush scr modules/om/src/om_setprop.php cmd $entity_type $featureid $varkey $propname $propvalue
done < /tmp/virtual_use_fractions.txt 