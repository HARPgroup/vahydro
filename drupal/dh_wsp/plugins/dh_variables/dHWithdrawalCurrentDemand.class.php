<?php
// @todo: figure out how to insure other plugin files are called when needed by this plugin
//        OR just move all the base classes into the module ?
module_load_include('inc', 'dh', 'plugins/dh.display');
module_load_include('module', 'dh');
// make sure that we have base plugins 
$plugin_def = ctools_get_plugins('dh', 'dh_variables', 'dHOMmodelElement');
$class = ctools_plugin_get_class($plugin_def, 'handler');
//dpm("so far so good");
  
class dHWithdrawalCurrentDemand extends dHVariablePluginDefault {
  
  public function hiddenFields() {
    $hidden = array('pid', 'featureid', 'entity_type', 'bundle', 'dh_link_admin_pr_condition', 'varid', 'field_prop_upload');
    return $hidden;
  }
  
  public function save(&$entity) {
    $this->updateFacility($entity);
    parent::save($entity);
  }
  
  public function updateFacility($entity) {
    // 1. If entity_type = dh_feature look for parent with dh_link_facility_mps
    //    if this is attached to a parent facility, update that facility value
    // 2. Check the type of entity 
    //    property expects only 1 value
    //    time series uses tstime/tsendtime
    if ($entity->entity_type == 'dh_feature') {
      $parent = dh_getMpFacilityHydroId($entity->featureid);
      if ($parent) {
        $summary_info = array(
          'featureid' => $parent,
          'entity_type' => 'dh_feature',
          'bundle' => $entity->bundle,
          'varid' => $entity->varid,
        );
      } else {
        return FALSE;
      }
      switch ($entity->entityType()) {
        case 'dh_timeseries':
        // add time specific constraints based on tscode setting 
          $valcol = 'tsvalue';
          $summary_info['tstime'] = $entity->tstime;
          $summary_info['tsendtime'] = $entity->tsendtime;
          $sing = 'tspan_singular';
          $read_fn = 'dh_get_timeseries';
          $write_fn = 'dh_update_timeseries';
          $idcol = 'tid';
        break;
        
        case 'dh_properties':
          $valcol = 'propvalue';
          $sing = 'singular';
          $read_fn = 'dh_get_properties';
          $write_fn = 'dh_update_properties';
          $idcol = 'pid';
          $summary_info['propname'] = $entity->propname;
        break;
        default:
          return FALSE;
        break;
      }
      $total = 0;
      $all_mps = dh_get_facility_mps($parent, FALSE, FALSE, FALSE);
      // get prop or ts associated with this
      foreach ($all_mps as $mp_hydroid) {
        $mp_info = $summary_info;
        $mp_info['featureid'] = $mp_hydroid;
        # get matching ts or prop ids if exists
        $summary_prec = $read_fn($mp_info, $sing);
        if ($summary_prec and isset($summary_prec[$entity->entityType()])) {
          // load the record and update total
          //dpm($summary_prec, 'loaded');
          $sid = array_shift($summary_prec[$entity->entityType()]);
          $mp_vid = $sid->{$idcol};
          $mp_data = entity_load_single($entity->entityType(), $mp_vid);
          //dpm($mp_data, "Adding $mp_vid to summary");
          if ($mp_data->featureid <> $entity->featureid) {
            $total += $mp_data->{$valcol};
          } else {
            // handle this one specially to make sure we get current data
            $total += $entity->{$valcol};
          }
        }
      }
      $summary_info[$valcol] = $total;
      //dpm($summary_info,"final record to $write_fn");
      $write_fn($summary_info, $sing);
    }
    return FALSE;
  }
  
  public function updateTotals(&$entity) {
    //@tbd
    // Find max complete year of data (either last year with 12 reporting, or current year minus 1, or allow override)
    $year = date('Y', dh_handletimestamp($entity->tstime));
    $begin = dh_handletimestamp("$year-01-01 00:00:00");
    $end = dh_handletimestamp("$year-12-31 00:00:00");
    $summary = dh_summarizeTimePeriod($entity->entity_type, $entity->featureid, $entity->varid, $begin, $end);
    if (!empty($summary)) {
      $summary['varkey'] = $this->rep_varkey;
      $summary['tsvalue'] = $summary['sum_value'];
      $tid = dh_update_timeseries($summary, 'tstime_singular');
      //dpm($summary, "Updated TID $tid $this->rep_varkey Annual $year-01-01 to $year-12-31 From Monthly " . date("Y-m-d", $entity->tstime));
    } else {
      dsm("dh_summarizeTimePeriod returned FALSE ");
    }
    parent::updateLinked($entity);
  }
}
?>