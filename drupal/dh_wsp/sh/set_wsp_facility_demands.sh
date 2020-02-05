#!/bin/bash
hydroids=$1

cat modules/dh_wsp/sql/create_wsp_facility_demands.sql | psql -h dbase2 drupal.dh03 

frac_query="
select 'dh_feature' as entity_type, 
  hydroid as featureid, 
  'wsp_facility_mgy' as varkey,
  'wsp2020_2020_mgy' as propname, 
  sum(fac_net_wd) as propvalue, 
  'wsp_current_use_mgy' as propcode 
from tmp_wsp_fac_net 
where hydroid in ($hydroids)
group by hydroid;
"
echo $frac_query | PGOPTIONS='--client-min-messages=warning' psql -h dbase2 drupal.dh03 > /tmp/wsp_facility_current.txt 

n=`< /tmp/wsp_facility_current.txt wc -l`
nm="$((n - 2))"
head -n $nm /tmp/wsp_facility_current.txt > /tmp/fhead.txt 
n=`< /tmp/fhead.txt wc -l`
nm="$((n - 4))"
tail -n $nm /tmp/fhead.txt > /tmp/wsp_facility_current.txt 

while IFS= read -r line; do
  #echo "Text read from file: $line"
  IFS="$IFS|" read entity_type featureid varkey propname propvalue propcode <<< "$line"
  drush scr modules/om/src/om_setprop.php cmd $entity_type $featureid $varkey $propname $propvalue $propcode
done < /tmp/wsp_facility_current.txt 

# NOW DO FUTURE
frac_query="
select 'dh_feature' as entity_type, 
  hydroid as featureid, 
  'wsp_facility_mgy' as varkey,
  'wsp2020_2040_mgy' as propname, 
  sum(fac_net_future_wd) as propvalue, 
  'wsp_future_use_mgy' as propcode 
from tmp_wsp_fac_net 
where hydroid in ($hydroids)
group by hydroid;
"
echo $frac_query | PGOPTIONS='--client-min-messages=warning' psql -h dbase2 drupal.dh03 > /tmp/wsp_facility_future.txt 

n=`< /tmp/wsp_facility_future.txt wc -l`
nm="$((n - 2))"
head -n $nm /tmp/wsp_facility_future.txt > /tmp/fhead.txt 
n=`< /tmp/fhead.txt wc -l`
nm="$((n - 4))"
tail -n $nm /tmp/fhead.txt > /tmp/wsp_facility_future.txt 

while IFS= read -r line; do
  #echo "Text read from file: $line"
  IFS="$IFS|" read entity_type featureid varkey propname propvalue propcode <<< "$line"
  drush scr modules/om/src/om_setprop.php cmd $entity_type $featureid $varkey $propname $propvalue $propcode
done < /tmp/wsp_facility_future.txt 

# Now clean up
cat modules/dh_wsp/sql/cleanup_wsp_facility_demands.sql | psql -h dbase2 drupal.dh03
