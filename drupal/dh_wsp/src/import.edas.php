#!/user/bin/env drush
<?php


function dh_get_feature($hydrocode, $bundle) {
  global $mp_cache;
  if (isset($mp_cache[$bundle][$hydrocode])) {
    return $mp_cache[$bundle][$hydrocode];
  }
  $efq = new EntityFieldQuery;
  $efq->entityCondition('entity_type', 'dh_feature');
  $efq->propertyCondition('bundle', $bundle, '=');
  $efq->propertyCondition('hydrocode', $hydrocode, '=');
  $result = $efq->execute();
  if (!isset($result['dh_feature'])) {
    return FALSE;
  }
  $mp_cache[$bundle][$hydrocode] = array_shift($result['dh_feature']);
  return $mp_cache[$bundle][$hydrocode];
}

//$file = '/var/www/html/files/hwi/vahydro_samples_fish.txt';
// use this for only the last 149,000 records (got interrupted)
$file = '/var/www/html/files/hwi/vahydro_samples_fish-last149k.txt';
$handle = fopen($file, 'r');
$varid = dh_varkey2varid('weather_obs');
$varid = is_array($varid) ? array_shift($varid) : $varid;
$keys = array('sampleid', 'stationid', 'propvalue', 'propname', 'repnum', 'propcode', 'colldate');
$i = 0;
$test_only = FALSE;
echo "Processed ";
$summaries = array(); 
// $summaries = array(
//   2 => array(
//     '2017-06-01' => '2017-05-01',
// if current date does not match last date, do summary using tstime_date_singular setting
$event_cache = array(); // cache for events
$vars = dh_varkey2varid('aqbio_sample_event');
$event_varid = array_shift($vars);
$vars = dh_varkey2varid('aqbio_org_fish');
$org_varid = array_shift($vars);
while ($values = fgetcsv($handle, 0, "\t")) {
  // get the station hydroid
  //  -- create one if non existent
  // check for the sample event TS matching sampleid-repnum
  // -- create one if non exec
  // add/update properties matching for this species (propcode) and sample event tid with species count
  
  $i++;
  if ($i == 1) {
    // skip the header
    continue;
  }
  $organism = array_combine($keys, $values);
  $mp = dh_get_feature($organism['stationid'], 'monitoringpoint');
  if ($i <= 10) { 
   // echo "values " . implode(', ', $organism) . "\n";
   // echo "Organism record " . implode(', ', $organism) . "\n";
  }
  if (!$mp) {
    drupal_set_message("Non-existent hydrocode $organism[stationid] ... Adding");
  }
  $event_info = array(
    'varid' => $event_varid,
    'entity_type' => 'dh_feature',
    'featureid' => $mp->hydroid,
    'tstime' => dh_handletimestamp($organism['colldate']),
    'tscode' => implode('-',array($organism['sampleid'],$organism['repnum']))
  );
  if (!isset($event_cache[$event_info['tscode']])) {
    // here we use tstimecode_singular to catch bad daylight savings shifts
    // if we get no record, we will try to create it, but use tscode_singular which will insure over-writing
    $event_recs = dh_get_timeseries($event_info, 'tstimecode_singular');
    if (!$event_recs) {
      // we need to create the sample event
      echo "Creating Sample Event " . print_r($event_info,1) . "\n";
      // use tscode_singular which will insure over-writing if we have an event with the same tscode/varid
      // but with a different tstime due to daylight savings shifts
      $tid = dh_update_timeseries($event_info, 'tscode_singular');
    } else {
      $event = array_shift($event_recs['dh_timeseries']);
      $tid = $event->tid;
      //echo "Found Sample Event " . print_r($event_info,1) . "\n";
      echo "Found Sample Event " . $tid . "\n";
    }
    $event_cache[$event_info['tscode']] = $tid;
  } else {
    // already seen this event, 
    $tid = $event_cache[$event_info['tscode']];
      echo "Cached Sample Event " . $tid . "\n";
  }
  $organism ['featureid'] = $tid;
  $organism ['entity_type'] = 'dh_timeseries';
  $organism ['varid'] = $org_varid;
  $organism ['bundle'] = 'dh_properties';
    
  //echo "Adding Organism to Event " . print_r($organism,1) . "\n";
  echo "Adding Organism to Event $organism[propname] \n";
  dh_update_properties($organism, 'name');
  if ($test_only and ($i > 100)) {
    break;
  }
  if ( ($i/500) == intval($i/500)) {
    echo "... $i ";
  }
}

echo " - total $i records (testing = $test_only)";

?>