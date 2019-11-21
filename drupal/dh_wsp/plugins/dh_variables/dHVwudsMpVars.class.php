<?php
module_load_include('inc', 'dh', 'plugins/dh.display');
module_load_include('module', 'dh');
// make sure that we have base plugins 
$plugin_def = ctools_get_plugins('dh', 'dh_variables', 'dHOMmodelElement');
$class = ctools_plugin_get_class($plugin_def, 'handler');
// make sure that we have base plugins 
$plugin_def = ctools_get_plugins('dh', 'dh_variables', 'dHVarWithTableFieldBase');
$class = ctools_plugin_get_class($plugin_def, 'handler');

class dHWspMpActivityStatus extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    //dpm($rowform,'rowform');
    // apply custom settings here
    $opts = array(
      'active' => 'Active',
      'inactive' => 'Inactive (no withdrawal this year)',
      'abandoned' => 'Permanently Abandoned',
      'proposed' => 'Proposed',
      'duplicate' => 'Duplicate',
      'unknown' => 'Unknown',
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
    );
    $rowform[$this->row_map['start']]['#description'] = t('Date that this source went into operation.');
    $rowform[$this->row_map['start']]['#weight'] = 2;
    $rowform[$this->row_map['end']]['#description'] = t('Date that this source was removed/inactivated.  Leave blank if source is still active/temporarily Inactive.');
    $rowform[$this->row_map['end']]['#weight'] = 3;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHVdhPwsid extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $rowform[$this->row_map['code']] = array(
      '#type' => 'textfield',
      '#default_value' => $row->{$this->row_map['code']},
      '#weight' => 1,
      '#description' => 'VDH PWSID if applicable',
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHVpdesPermitno extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $rowform[$this->row_map['code']] = array(
      '#type' => 'textfield',
      '#default_value' => $row->{$this->row_map['code']},
      '#weight' => 1,
      '#description' => 'VPDES Permit # if applicable.',
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHVwudsSourceType extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'gw' => 'Groundwater',
      'sw' => 'Surface Water',
      'tw' => 'Transferred Water'
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Select Source Type if above is incorrect, or has changed',
      '#title' => 'Source Type'
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
	  $rowform['#weight']=1;
    //dpm($rowform, 'sourceProps plugin form row');
  }
  
}

class dHVwudsSourceSubtype extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'well' => 'Well',
      'spring' => 'Spring',
      'reservoir' => 'Reservoir',
      'stream' => 'Stream',
      'transfer' => 'Transfer',
      'unknown' => 'Unknown/Other',
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Water source sub-type',
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
  }
}

  
class dHWithdrawalCurrentDemand extends dHVariablePluginDefault {
  
  public function hiddenFields() {
    $hidden = array('pid', 'featureid', 'entity_type', 'bundle', 'dh_link_admin_pr_condition', 'varid', 'field_prop_upload');
    return $hidden;
  }
  
  public function save(&$entity) {
    $this->updateFacility($entity);
    parent::save();
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
        break;
        default:
          return FALSE;
        break;
      }
      $total = 0;
      $all_mps = dh_get_facility_mps($parent);
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
}

class dHMonthlyFractionFactors extends dHVarWithTableFieldBase {
  var $raw_data_varkey = 'wd_mgm'; // what to use to accumulate sorted by months, then divide into total to get % of annual
  var $default_bundle = 'om_data_matrix';
  var $matrix_field = 'field_dh_matrix';

  public function hiddenFields() {
    return array('pid', 'startdate', 'enddate', 'varid', 'featureid', 'entity_type', 'bundle','dh_link_admin_pr_condition', 'propvalue');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // special render handlers when displaying in a grouped property block
    // $row->propvalue = number_format($row->propvalue, 3);
  }
	
  public function formRowEdit(&$rowform, $entity) {
    // call parent class to insure proper bundle and presence of tablefield
    parent::formRowEdit($rowform, $entity);
    $rowform['propvalue']['#type'] = 'hidden';
    $rowform[$this->matrix_field]['#description'] = t('Monthly Fractions of Annual Total');
	$opts = array(
	  'automatic' => 'Automatic',
      'manual' => 'Manual',
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
	  '#description' => 'Select Default Update Behavior',
    );
  }
  
  public function tableDefault($entity) {
    // Returns simple array keyed table
    $default_table = array();
    //$mos = array('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec');
    $mos = array('mo_num', 'mo_frac');
    $default_table[] = $mos;
    //$all_defaults = array_fill_keys(array_keys($mos), 0.0833);
    //$default_table[] = $all_defaults;
    $cat_defaults = $this->waterUserCategoryDefaults($entity);
    //$historical = $this->getHistoricalMonthlyDistro($entity);
    //$historical = $this->getHistoricalMonthlyDistroRows($entity);
    $historical = $this->getHistoricalMonthlyDistroRowsALL($entity);
    if (!empty($cat_defaults)) {
      $default_table[1] = $cat_defaults;
    }
    if (!empty($historical)) {
      //$default_table[1] = $historical;
      $default_table[1] = $historical; //[] is first row, [1] is second row
    }
    return $default_table;
    //return $historical;
  }

  public function getHistoricalMonthlyDistroRowsALL($entity) {
    $sql = " SELECT mo_num, "; 
    $sql .= "   CASE WHEN ann_sum IS NULL OR ann_sum = 0 THEN 0.0833 ";
    $sql .= "     ELSE CAST ((mo_sum/ann_sum) as decimal(10,4)) ";
    $sql .= "   END AS mo_frac ";
    $sql .= " FROM ( ";
    $sql .= "   SELECT date_part('month',to_timestamp(tstime)) AS mo_num, SUM(tsvalue) AS mo_sum ";
    $sql .= "   FROM dh_timeseries ";
    $sql .= "   INNER JOIN dh_variabledefinition ON dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   WHERE featureid IN (SELECT entity_id FROM field_data_dh_link_facility_mps WHERE dh_link_facility_mps_target_id = $entity->featureid) ";
    $sql .= "    AND dh_variabledefinition.varkey = '$this->raw_data_varkey' "; 
    $sql .= "    GROUP BY date_part('month',to_timestamp(tstime)) ";
    $sql .= "    ORDER BY date_part('month',to_timestamp(tstime)) ";
    $sql .= " ) AS foo ";
    $sql .= " LEFT OUTER JOIN ( ";
    $sql .= " SELECT SUM(tsvalue) AS ann_sum ";
    $sql .= "   FROM dh_timeseries ";
    $sql .= "   INNER JOIN dh_variabledefinition ON dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   WHERE featureid IN (SELECT entity_id FROM field_data_dh_link_facility_mps WHERE dh_link_facility_mps_target_id = $entity->featureid) ";
    $sql .= "    AND dh_variabledefinition.varkey = '$this->raw_data_varkey' ";
    $sql .= " ) AS bar ";
    $sql .= " ON (1 = 1) ";
    $sql .= " WHERE ann_sum > 0 ";    
        
    dpm($sql,'sql');        
    $result = db_query($sql);
    dpm($result,'result'); //the query appears to be OK, its the fetch command that is only returning the first row
    //$record = $result->fetchAssoc();
    //$record = $result->fetchAll(); //fetchAll() is closer...
    //$record = $result->fetchAllKeyed();
    //$record = $result->fetchAllAssoc();
    
    //$record = $result->fetchAssoc();

    //while ($record = $result->fetchAssoc()) {
    //  dpm($record,'record');
    //}
    
    $record=[];
    while ($array = $result->fetchAssoc()) {
      dpm($array,'array');
      $record = array_merge($record, $array);
    }
    dpm($record,'record');
    
    //$record=[];
    //foreach($array = $result->fetchAssoc()){
    //$record = array_merge($record, $array);
    //}
    //dpm($record,'record');
    
    //dpm($record,'record');
    //return array_values($record); 
  }
  

  
  public function getHistoricalMonthlyDistroRows($entity) {
    // Put SQL code here and transform into a CSV style array with 12 monthly fraction values.
    // example: return array(0.0833, 0.0833,...);	
	  $sql = "  select thismo, ";
    $sql .= " case ";
    $sql .= "   when sum_mon.total is null then 0.0000 ";
    $sql .= "   else cast((sum_mon.total / annual.sum_all) as decimal(10,4)) ";
    $sql .= " end as pct_of_annual ";
    $sql .= " from  ";
    $sql .= "   (select to_char(to_timestamp(tstime), 'MM') as thismo, sum(tsvalue) as total ";
    $sql .= "   from dh_timeseries as ts ";
    $sql .= "   inner join dh_variabledefinition as vd on ts.varid = vd.hydroid ";
    $sql .= "   where featureid in ( ";
    $sql .= "     select entity_id  ";
    $sql .= "     from field_data_dh_link_facility_mps   ";
    $sql .= "     where dh_link_facility_mps_target_id = $entity->featureid  ";
    $sql .= "     and entity_type = 'dh_feature' ";
    $sql .= "   ) ";
    $sql .= "   and vd.varkey = '$this->raw_data_varkey'  ";
    $sql .= "   and date_part('month',to_timestamp(tstime)) = 1 ";
    $sql .= " ) as sum_mon ";
    $sql .= " left outer join (";
    $sql .= "   select sum(tsvalue) as sum_all ";
    $sql .= "   from dh_timeseries as ts ";
    $sql .= "   inner join dh_variabledefinition as vd on ts.varid = vd.hydroid ";
    $sql .= "   where featureid in ( ";
    $sql .= "     select entity_id  ";
    $sql .= "     from field_data_dh_link_facility_mps  ";
    $sql .= "     where dh_link_facility_mps_target_id = $entity->featureid  ";
    $sql .= "       and entity_type = 'dh_feature' ";
    $sql .= "    ) ";
	  $sql .= "	  and vd.varkey = '$this->raw_data_varkey' ";
    $sql .= " ) as annual" ;
	$sql .= "	on (1 = 1) ";
	$sql .= "	where annual.sum_all > 0 ";
    // @todo: 
    //   1. replace all instances of 72023 with $entity->featureid, 
    //   2. replace all instances of wd_mgm with $this->raw_data_varkey, 
    //   3. add clause in SQL to filter entity_type = 'dh_feature'
    //   4. test on d.bet - make sure that the line "if (!empty($historical)) {" in function tableDefault($entity) behaves as expected.
    
    //dpm($sql,'sql');
    $result = db_query($sql);
	  //dpm($result,'result');
    $record = $result->fetchAssoc();
	  //dpm($record,'record');
    return array_values($record); 
  }

  public function getHistoricalMonthlyDistro($entity) {
    // Put SQL code here and transform into a CSV style array with 12 monthly fraction values.
    // example: return array(0.0833, 0.0833,...);	
	$sql = "select		case when jan.sum_jan is null then 0.0000 else cast((jan.sum_jan / annual.sum_all) as decimal(10,4)) end as jan_fac, ";
    $sql .= "			case when feb.sum_feb is null then 0.0000 else cast((feb.sum_feb / annual.sum_all) as decimal(10,4)) end as feb_fac, ";
    $sql .= "			case when mar.sum_mar is null then 0.0000 else cast((mar.sum_mar / annual.sum_all) as decimal(10,4)) end as mar_fac, ";
    $sql .= "			case when apr.sum_apr is null then 0.0000 else cast((apr.sum_apr / annual.sum_all) as decimal(10,4)) end as apr_fac, ";
    $sql .= "			case when may.sum_may is null then 0.0000 else cast((may.sum_may / annual.sum_all) as decimal(10,4)) end as may_fac, ";
    $sql .= "			case when jun.sum_jun is null then 0.0000 else cast((jun.sum_jun / annual.sum_all) as decimal(10,4)) end as jun_fac, ";
    $sql .= "			case when jul.sum_jul is null then 0.0000 else cast((jul.sum_jul / annual.sum_all) as decimal(10,4)) end as jul_fac, ";
    $sql .= "			case when aug.sum_aug is null then 0.0000 else cast((aug.sum_aug / annual.sum_all) as decimal(10,4)) end as aug_fac, ";
    $sql .= "			case when sep.sum_sep is null then 0.0000 else cast((sep.sum_sep / annual.sum_all) as decimal(10,4)) end as sep_fac, ";
    $sql .= "			case when oct.sum_oct is null then 0.0000 else cast((oct.sum_oct / annual.sum_all) as decimal(10,4)) end as oct_fac, ";
    $sql .= "			case when nov.sum_nov is null then 0.0000 else cast((nov.sum_nov / annual.sum_all) as decimal(10,4)) end as nov_fac, ";
    $sql .= "			case when dec.sum_dec is null then 0.0000 else cast((dec.sum_dec / annual.sum_all) as decimal(10,4)) end as dec_fac  ";
    $sql .= "   from  ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_jan ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
    $sql .= "   	and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 1 ";
    $sql .= "   ) jan, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_feb ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
    $sql .= "   	and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 2 ";
    $sql .= "   ) feb, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_mar ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 3 ";
    $sql .= "   ) mar, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_apr ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 4 ";
    $sql .= "   ) apr, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_may ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') "; 
	$sql .= "   	and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 5 ";
    $sql .= "   ) may, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_jun ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "   	and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 6 ";
    $sql .= "   ) jun, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_jul ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= " 		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 7 ";
    $sql .= "   ) jul, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_aug ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 8 ";
    $sql .= "   ) aug, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_sep ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 9 ";
    $sql .= "   ) sep, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_oct ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') "; 
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 10 ";
    $sql .= "   ) oct, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_nov ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 11 ";
    $sql .= "   ) nov, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_dec ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' and date_part('month',to_timestamp(tstime)) = 12 ";
    $sql .= "   ) dec, ";
    $sql .= "    ";
    $sql .= "   (select sum(tsvalue) as sum_all ";
    $sql .= "   from dh_timeseries ";
    $sql .= "   inner join dh_variabledefinition on dh_timeseries.varid = dh_variabledefinition.hydroid ";
    $sql .= "   where featureid in (select entity_id from field_data_dh_link_facility_mps where dh_link_facility_mps_target_id = $entity->featureid and entity_type = 'dh_feature') ";
	$sql .= "		and dh_variabledefinition.varkey = '$this->raw_data_varkey' ";
    $sql .= "   ) annual" ;
	$sql .= "	where annual.sum_all > 0 ";
    // @todo: 
    //   1. replace all instances of 72023 with $entity->featureid, 
    //   2. replace all instances of wd_mgm with $this->raw_data_varkey, 
    //   3. add clause in SQL to filter entity_type = 'dh_feature'
    //   4. test on d.bet - make sure that the line "if (!empty($historical)) {" in function tableDefault($entity) behaves as expected.
    
    dpm($sql,'sql');
    $result = db_query($sql);
	  dpm($result,'result');
    $record = $result->fetchAssoc();
	  dpm($record,'record');
    return array_values($record); 
  }

  public function save(&$entity) {
    if (empty ($entity->propcode)) {
      $entity->propcode='automatic';
    }
    if ($entity->propcode=='automatic') {
      $datatable = $this->tableDefault($entity);
      $this->setCSVTableField($entity, $datatable);
    }
  }

  public function waterUserCategoryDefaults($entity) {
    // load ftype from featureid
    $default = FALSE;
    $cat_defaults = array(
      'irrigation' => array(0.0000,0.0000,0.0000,0.0000,0.0000,0.2500,0.2500,0.2500,0.2500,0.0000,0.0000,0.0000),
    );
    // get defaults for that ftype if set, otherwise return FALSE
    $feature = $this->getParentEntity($entity);
    if (is_object($feature)) {
      $default = isset($cat_defaults[$feature->ftype]) ? $cat_defaults[$feature->ftype] : FALSE;
    }
    return $default;

  }
}


class dHWaterMeterReading extends dHVariablePluginDefault {
  var $quantity_varkey = 'wlg';
  
  public function codeOptions() {
    $options = array(
      'none' => 'N/A', 
      'reading' => 'Reading', 
      'rollover' => 'Roll-Over', 
      'replacement' => 'Replacement',
      'initialize' => 'Initial Reading',
    );
    global $user;
    $admin_users = array('gw permit writer', 'administrator', 'planner');
    //dpm($user,'user');
    if (! (count(array_intersect($admin_users, array_values($user->roles))) > 0) ) {
      unset($options['initialize']);
    }
    return $options;
  }
  
  public function formRowEdit(&$form, $entity) {
    //error_log("Form #id = " . $form['#id']);
    //$form['tstime']['#weight'] = 1;
    //$form['tsendtime']['#weight'] = 2;
    //$form['tsvalue']['#weight'] = 3;
    //$form['proptext']['#weight'] = 4;
    //dpm($entity,'entity');
    $form['tstime'] = array(
      '#coltitle' => 'Month',
      '#prefix' => !empty($entity->tstime) ? date('M', $entity->tstime) : 'unk',
      '#type' => 'hidden',
      '#default_value' => $entity->tstime,
    );
        
    $form['tsvalue']['#coltitle'] = 'Meter Reading';
    $form['tsvalue']['#required'] = FALSE;
    $form['tsvalue']['#size'] = 24;
    $form['tsvalue']['#ajax'] = array(
      //'callback' => 'dh_wsp_rebuild_dh_wsp_gwp_monthly_form',
      //'wrapper' => 'net_wd-' . $entity->form_element_index,
      'wrapper' => 'dh-wsp-gwp-monthly-form',
      'field_name' => 'net_wd',
    );
    
    $form['tscode']['#type'] = 'select';
    $form['tscode']['#multiple'] = FALSE;
    $form['tscode']['#size'] = 1;
    $form['tscode']['#default_value'] = !empty($entity->tscode) ? $entity->tscode : 'reading';
    //$form['tscode']['#value'] = !empty($entity->tscode) ? $entity->tscode : 'reading';
    $form['tscode']['#coltitle'] = 'Reading Type';
    // this works, but automatically redirects to save & next
    // also, does not have the text
    /*
    $form['tscode']['#attributes'] = array(
      'onchange' => 'this.form.submit();'
      'onchange' => 'alert("You must choose Save & Reload");'
    );
    */
    
    /*
    // uncomment to try in vain to get ajax refresh working...
    $form['tscode']['#ajax'] = array(
      // use this to rebuild just the data entry field
      //'callback' => 'dh_rebuild_plugin_row',
      //'wrapper' => 'net_wd-' . $entity->form_element_index,
      // use this to rebuild entire form
      'callback' => 'dh_wsp_gwp_monthly_form_rebuild',
      //'callback' => 'drupal_form_submit',
      //'callback' => 'dh_wsp_gwp_monthly_form_submit',
      //'wrapper' => 'dh-wsp-gwp-monthly-form',
      'wrapper' => 'dh-wsp-gwp-monthly-form-block',
      'method' => 'replace',
      'effect' => 'fade',
    );
    */
    
    
    $value_types = $this->codeOptions();
    $form['tscode']['#options'] = $value_types;
    $quantity = $this->loadReplicant($entity, $this->quantity_varkey);
    //dpm($quantity,'quant');
    if ($entity->tscode == 'reading') {
      $last_reading = $this->getLastReading($entity);
      //dpm($last_reading,'last reading');
      //error_log('Current : ' . $entity->tsvalue);
      //error_log('Last value: ' . $last_reading->tsvalue);
      //dpm($last_reading,'last reading');
      $quantity->tsvalue = $entity->tsvalue - $last_reading->tsvalue;
      //error_log('Net WD: ' . $quantity->tsvalue);
      error_log("(t) $entity->tsvalue - (t-1) $last_reading->tsvalue =  $quantity->tsvalue");
    } else {
      if (property_exists($entity, 'net_wd')) {
        $quantity->tsvalue = $entity->net_wd;
      }
    }
    // set up net_wd field info and writeability
    $wdtype_id = 'ts_group[' . $entity->form_element_index . '][tscode]';
    $net_wd_jqid = ':input[name="' . $wdtype_id . '"]';
    $man_states_enabled = array();
    $man_states_disabled = array();
    $manual = array('rollover', 'replacement', 'initialize');
    $auto = array('reading', 'none');
    foreach ($manual as $man) {
      $man_states_enabled[] = array(
        "$net_wd_jqid" => array('value' => $man)
      );
    }
    foreach ($auto as $aut) {
      $man_states_disabled[] = array(
        "$net_wd_jqid" => array('value' => $aut)
      );
    }
    // @todo: do we need to? get the last value reported to calculate amount withdrawn
    $atts = array();
    if (!in_array($entity->tscode, $manual)) {
      // uncomment to try in vain to get ajax refresh working...
      //$atts['disabled'] = TRUE;
      $value_message = t('Automatically Calculated.');
      $next_message = t('Enter withdrawal amount here.');
    } else {
      $value_message = t('Enter withdrawal amount here.');
      $next_message = t('Automatically Calculated.');
    }
    $form['net_wd'] = array(
      //'#type' => in_array($entity->tscode, $manual) ? 'textfield' : 'hidden',
      '#type' => 'textfield',
      '#attributes' => $atts,
      '#coltitle' => 'Total Withdrawn',
      '#title' => 'Monthly Withdrawal Amount',
      //'#title' =>  "<div id='net_wd-text-" . $entity->form_element_index . "'>" . $value_message . "</div>",
      '#size' => 24,
      //'#disabled' => in_array($entity->tscode, $manual) ? FALSE : TRUE,
      '#default_value' => $quantity->tsvalue,
      '#states' =>  array(
        'required' => $man_states_enabled,
        'enabled' => $man_states_enabled,
        'disabled' => $man_states_disabled,
      // #title field will be hidden if field is invisible, so we use this to control instructions to enter amt
        'visible' => $man_states_enabled,
        'invisible' => $man_states_disabled,
      ),
      '#element_validate' => array('element_validate_number'), 
      //'#value' => $quantity->tsvalue,
      '#suffix' => $quantity->tsvalue,
      //'#prefix' => "<div id='net_wd-" . $entity->form_element_index . "'>" 
      //  . in_array($entity->tscode, $manual) ? '' : $quantity->tsvalue,
      //'#suffix' => "</div>",
    );
    $form['net_wd']['extra'] = array(
      '#markup' => 'Some text here',
      '#prefix' => 'Some text here',
      '#suffix' => 'Some text here',
    );
      
    //dpm($form, 'form');
    //error_log('$quantity->tsvalue = ' . $quantity->tsvalue);
    //dpm($this,'water_meter_reading form');
    //dpm($entity->form_state,'entity->form_state form');

  }
  
  public function save(&$entity) {
    // add a ts event to note a insert or edit
    //dpm($entity,'save ');
    // don't call updateLinked from save() there may be no tid therefore no way to link
    //  anything linked should be called in update()
    //$this->updateLinked($entity);
    parent::save($entity);
  }
  
  public function update(&$entity) {
    // pass updates to all objects linked to this.
    // update occurs after save().
    // we do this on update, but not on insert, 
    // since if it is an insert there won't be anything linked to it yet
    //dpm($entity,'update ');
    $this->updateLinked($entity);
    parent::update($entity);
  }
  
  public function insert(&$entity) {
    // add a ts event to note an insert or edit
    //dpm($entity,'insert ');
    //$this->recordChange($entity);
    $this->updateLinked($entity);
    parent::insert($entity);
  }
  
  public function formRowSave(&$rowvalues, &$row) {
    // @todo: handle saving of 
    //dpm($row,'formRowSave ');
  }
  
  public function getLastReading($entity) {
    // @todo determine the last months tstime and query for it
    // return the tsvalue field or 0.0 
    $tstime = dh_handletimestamp($entity->tstime);
    $thisyear = date('Y', $tstime);
    $thismonth = date('m', $tstime);
    if ($thismonth == 1) {
      $lastmonth = 12;
      $lastyear = $thisyear - 1;
    } else {
      $lastmonth = $thismonth - 1;
      $lastyear = $thisyear;
    }
    $lasttime = dh_handletimestamp("$lastyear-$lastmonth-01");
    $last_info = array(
      'featureid' => $entity->featureid,
      'entity_type' => $entity->entity_type,
      'tstime' => $lasttime,
      'varid' => $entity->varid,
    );
    
    $last_reading = FALSE;
    if (property_exists($entity, 'form_state') and !empty($entity->form_state) and $entity->form_state['rebuild']) {
      $last_reading = $this->searchFormState($entity->form_state, $last_info);
    }
    
    if (!$last_reading) {
      $result = dh_get_timeseries($last_info, 'tstime_singular');
      if (isset($result['dh_timeseries'])) {
        $data = entity_load('dh_timeseries', array_keys($result['dh_timeseries']));
        $last_reading = array_shift($data);
      }
    }
    return $last_reading;
  }
  
  function searchFormState($form_state, $info, $entity_type) {
    
    //error_log("Searching last record " . date('Y-m-d',$info['tstime']) . ": " . print_r($info,1));
    $result = FALSE;
    if (!empty($form_state) and $form_state['rebuild']) {
      // query the form state for these first
      //$data = dh_search_form_state($form_state['entities'], array(), $info, $data, FALSE);
      $data = dh_search_form_state($form_state['values'], array(), $info, $data, FALSE);
      //error_log("All data from form_state " . print_r($data,1));
      if (!empty($data)) {
        // just take the first one
        $values = array_shift($data);
        if (count($data) > 0) {
          watchdog('dh', 'dh_search_form_state returned more than 1 entity -- only 1 expected. ' . print_r($criteria,1));
        }
        if (!empty($values['tid'])) {
          $result = entity_load_single('dh_timeseries', $values['tid']);
        } else {
          $result = entity_create('dh_timeseries', $values);
        }
        //error_log("Found in form_state " . date('Y-m-d',$values['tstime']) . ": " . print_r($values,1));
        // now, load the updated values onto this objects
        $this->applyEntityProperties($result, $values);
      }
      
    }
    return $result;
  }
  
  public function applyEntityProperties(&$entity, $record_group, $allprops = FALSE) {
    foreach ($record_group as $key => $val) {
      if (property_exists($entity, $key) or $allprops) {
        $entity->{$key} = $val;
      }
    }
  }
  
  public function updateLinked(&$entity) {
    //dpm($entity,'updating linked');
    // @todo: put a stub for this in the base class
    // iterate through things linked to this and call a entity_load() and entity_save()
    $quantity = $this->loadReplicant($entity, $this->quantity_varkey);
    // load the previous months data
    // tscode = reading, rollover or replacement
    // if tscode <> 'reading' then we DO NOT calculate quantity, 
    // instead we use the value of the quantity field
    // which has already been saved in the method formRowSave() of this plugin
    if ($entity->tscode == 'reading') {
      $last_reading = $this->getLastReading($entity);
      //dpm($last_reading,'last reading');
      $quantity->tsvalue = $entity->tsvalue - $last_reading->tsvalue;
    } else {
      //dpm($entity->net_wd, 'Setting value to manual');
      $quantity->tsvalue = $entity->net_wd;
    }
    if ($quantity) {
      //dpm($quantity,'updating linked quantity');
      entity_save('dh_timeseries', $quantity);
    }
  }
}

class dHAnnualWithdrawalMonthly extends dHVariablePluginDefault {
  var $stat = 'sum';
  var $varkey2sum = 'wlg';
  var $rep_varkey = 'wd_gpy';
  
  public function update(&$entity) {
    // update dopplegangers
    //dpm($entity, 'update');
    $this->updateLinked($entity);
    parent::update($entity);
  }
  
  public function insert(&$entity) {
    // update dopplegangers
    //dpm($entity, 'insert');
    $this->updateLinked($entity);
    parent::insert($entity);
  }
  
  public function updateLinked(&$entity) {
    // push monthly total to annual
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

class dHWithdrawalGPM extends dHAnnualWithdrawalMonthly {
  var $stat = 'sum';
  var $varkey2sum = 'wlg';
  var $rep_varkey = 'wd_gpy';
  
  public function updateLinked(&$entity) {
    
    // update for unit conversions
    // custom copy to monthly withdrawal in MG
    $replicant = $this->loadReplicant($entity, 'wd_mgm');
    $replicant->bundle = 'dh_timeseries';
    if (!($replicant === FALSE)) {
      //error_log("Updating dHAnnualWithdrawalGPY");
      //dpm($replicant, "Copying $entity->varid to mgmo");
      $replicant->tsvalue = $entity->tsvalue / 1000000.0;
      $rez = entity_save('dh_timeseries', $replicant);
    } else {
      dsm("loadReplicant returned FALSE (recursive or malformed info");
    }
    // now use parent methods to update annual total
    parent::updateLinked($entity);
  }
}

class dHWithdrawalMGM extends dHAnnualWithdrawalMonthly {
  var $stat = 'sum';
  var $varkey2sum = 'wd_mgm';
  var $rep_varkey = 'wd_mgy';
  // has all the same plumbing as the GPM
}

class dHDeliverylMGM extends dHAnnualWithdrawalMonthly {
  var $stat = 'sum';
  var $varkey2sum = 'dl_mgm';
  var $rep_varkey = 'dl_mgy';
  // has all the same plumbing as the GPM
}

class dHReleaseMGM extends dHAnnualWithdrawalMonthly {
  var $stat = 'sum';
  var $varkey2sum = 'rl_mgm';
  var $rep_varkey = 'rl_mgy';
  // has all the same plumbing as the GPM
}

class dHAnnualWithdrawalMGY extends dHVariablePluginDefault {
}

?>