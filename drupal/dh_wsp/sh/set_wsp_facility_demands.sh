#!/bin/bash
hydroids=$1

cat modules/dh_wsp/sql/create_wsp_facility_demands.sql | psql -h dbase2 drupal.dh03 

frac_query="
select 'wsp2020_2020_mgy' as propname, 
  'wsp_facility_mgy' as varkey,
  hydroid as featureid, 
  sum(fac_net_wd) as propvalue, 
  'dh_feature' as entity_type, 
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

# NOW DO FUTURE
frac_query=`cat modules/dh_wsp/sql/get_wsp_facility_future.sql`
echo $frac_query | PGOPTIONS='--client-min-messages=warning' psql -h dbase2 drupal.dh03 > /tmp/wsp_facility_current.txt 

n=`< /tmp/wsp_facility_future.txt wc -l`
nm="$((n - 2))"
head -n $nm /tmp/wsp_facility_future.txt > /tmp/fhead.txt 
n=`< /tmp/fhead.txt wc -l`
nm="$((n - 4))"
tail -n $nm /tmp/fhead.txt > /tmp/wsp_facility_future.txt 

while IFS= read -r line; do
  #echo "Text read from file: $line"
  IFS="$IFS|" read entity_type featureid varkey propname propvalue <<< "$line"
  drush scr modules/om/src/om_setprop.php cmd $entity_type $featureid $varkey $propname $propvalue
done < /tmp/wsp_facility_future.txt 

# Now clean up
cat modules/dh_wsp/sql/cleanup_wsp_facility_demands.sql | psql -h dbase2 drupal.dh03
