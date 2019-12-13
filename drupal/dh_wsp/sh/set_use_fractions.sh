#!/bin/bash

frac_query=`cat modules/dh_wsp/sql/create_use_fractions.sql`
echo $frac_query | psql -h dbase2 drupal.dh03 > /tmp/use_fractions.txt 

n=`< /tmp/use_fractions.txt wc -l`
nm="$((n - 2))"
head -n $nm /tmp/use_fractions.txt > /tmp/fhead.txt 
n=`< /tmp/fhead.txt wc -l`
nm="$((n - 2))"
tail -n $nm /tmp/fhead.txt > /tmp/use_fractions.txt 


while IFS= read -r line; do
  #echo "Text read from file: $line"
  IFS="$IFS|" read entity_type featureid varkey propname propvalue <<< "$line"
  drush scr modules/om/src/om_setprop.php cmd $entity_type $featureid $varkey $propname $propvalue
done < /tmp/use_fractions.txt 