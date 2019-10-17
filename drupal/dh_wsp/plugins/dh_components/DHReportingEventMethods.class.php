<?php

class DHReportingEventMethods extends DHTimeseriesGroupPreformatted {
  // @todo:
  //  save handlers
  //  formRowDefaults
  // viewBlock method
  var $event_id = FALSE;
  var $singular = TRUE; // should only one be allowed? Will trigger some duplicte prevention stuff
  var $year;
  var $method_varkey;
  var $maxday_varkey;
  var $meterloc_varkey;
  var $save_method = 'form_entity_map';
  var $groupname = 'methods';
  var $group_title = 'Measurement Methods';
  var $group_description = 'Methods of measurement, and Measurement Summaries.';
  // $entity_tokens - a list of variables that are eligible for token substitution
  var $entity_tokens = array('year', 'method_varkey', 'maxday_varkey', 'meterloc_varkey', 'featureid', 'entity_type');
  
  public function __construct($conf = array()) {
    parent::__construct($conf);
  }
  
  public function entityDefaults() {
    parent::entityDefaults();
    // HEADERS - sets before calling parent 
    $this->entity_defaults['method_varkey'] = 'water_meter_method';
    $this->entity_defaults['maxday_varkey'] = 'max_daily_wd_mgd';
    $this->entity_defaults['meterloc_varkey'] = 'water_meterloc';
    $this->entity_defaults['year'] = $this->getDefaultYear();
    $this->save_method = 'form_entity_map';
  }
  
  public function getDefaultYear() {
    $mo = date('n');
    $defyear = date('Y');
    if ($mo < 4) {
      $defyear = $defyear - 1;
    }
    return $defyear;
  }
  
  public function optionDefaults() {
    $this->property_conf_default = array(
      'tid' => array('name'=>'tid','hidden' => 1),
    );
  }
  
  public function propertyOptions(&$form, $form_state) {
    // this sets up properties that are to be controlled in the form
    // we override these to show only local things
    // it provides settings fields in the widget config form
    // as well as determining what gets included in the form presented to the user
    $form['entity_settings'][$this->groupname]['display']['properties'] = array();
  }  
  
  function prepareQueryDisabled() {
    // get desired varids
    // call parent method
    $vars = dh_varkey2varid(implode(',', array($this->meterloc_varkey, $this->method_varkey, $this->maxday_varkey, $this->status_varkey)));
    // query for varids matching these varkeys
    $this->varid = array();
    foreach ($vars as $var) {
      $this->varid[] = $var;
    }
    parent::prepareQuery();
  }
  
  function prepareQuery() {
    // all actual query setup will be done in getData since we use the form_entity_map
    // for this version
    $this->applyEntityTokens();
    $this->applySettings();
    if (count($this->featureid) == 0) {
      // @todo: proper error message here 
      return FALSE;
    }
    if ( (trim($this->year) == '') or ($this->year == 0)) {
      $this->year = $this->entity_defaults['year'];
    }
    // be cool with a date and just extract the year
    list($this->year) = explode('-', $this->year);
    $ei = $this->getTSEntityInfo();
    //dpm($ei,'e info');
    $entity_pkcol = ($ei['entity keys']['id']) ? $ei['entity keys']['id'] : 'hydroid';
    $entity_tbl = $ei['base table'];
    $q = "  select mp.$entity_pkcol as featureid, ";
    $q .= "   '$this->year-01-01'::timestamp as tstime, ";
    $q .= "   '$this->year-12-31'::timestamp as tsendtime, ";
    $q .= "   meterloc_var.hydroid as meterloc_varid, meterloc_data.tid as meterloc_tid, ";
    $q .= "   meterloc_var.varunits as meterloc_units, meterloc_data.tscode as meterloc_tscode, ";
    $q .= "   method_var.hydroid as method_varid, method_data.tid as method_tid, ";
    $q .= "   method_var.varunits as method_units, method_data.tscode as method_tscode, ";
    $q .= "   maxday_var.hydroid as maxday_varid, maxday_data.tid as maxday_tid, ";
    $q .= "   maxday_data.tsvalue as maxday_tsvalue, maxday_data.tscode as maxday_tscode, ";
    $q .= "   maxday_var.varunits as maxday_units, maxday_data.tstime as maxday_tstime ";
    $q .= " from $entity_tbl as mp ";
    // join in meter location variable and value
    $q .= " left outer join dh_variabledefinition as meterloc_var  ";
    $q .= " on (meterloc_var.varkey = '$this->meterloc_varkey') ";
    $q .= " left outer join dh_timeseries as meterloc_data ";
    $q .= " on ( ";
    $q .= "   meterloc_data.varid = meterloc_var.hydroid  ";
    $q .= "     and to_timestamp(meterloc_data.tstime) >= to_timestamp($this->year || '-01-01', 'YYYY-MM-DD' ) ";
    $q .= "     and to_timestamp(meterloc_data.tstime) <= to_timestamp($this->year || '-12-31', 'YYYY-MM-DD' ) ";
    $q .= "     and meterloc_data.featureid = mp.$entity_pkcol ";
    $q .= "     and meterloc_data.entity_type = '$this->ts_entity_type' ";
    $q .= " ) ";
    // join in meter method variable and value
    $q .= " left outer join dh_variabledefinition as method_var  ";
    $q .= " on (method_var.varkey = '$this->method_varkey') ";
    $q .= " left outer join dh_timeseries as method_data ";
    $q .= " on ( ";
    $q .= "   method_data.varid = method_var.hydroid  ";
    $q .= "     and to_timestamp(method_data.tstime) >= to_timestamp($this->year || '-01-01', 'YYYY-MM-DD' ) ";
    $q .= "     and to_timestamp(method_data.tstime) <= to_timestamp($this->year || '-12-31', 'YYYY-MM-DD' ) ";
    $q .= "     and method_data.featureid = mp.$entity_pkcol ";
    $q .= "     and method_data.entity_type = '$this->ts_entity_type' ";
    $q .= " ) ";
    // join in max day location variable and value
    $q .= " left outer join dh_variabledefinition as maxday_var  ";
    $q .= " on (maxday_var.varkey = '$this->maxday_varkey') ";
    $q .= " left outer join dh_timeseries as maxday_data ";
    $q .= " on ( ";
    $q .= "   maxday_data.varid = maxday_var.hydroid  ";
    $q .= "     and to_timestamp(maxday_data.tstime) >= to_timestamp($this->year || '-01-01', 'YYYY-MM-DD' ) ";
    $q .= "     and to_timestamp(maxday_data.tstime) <= to_timestamp($this->year || '-12-31', 'YYYY-MM-DD' ) ";
    $q .= "     and maxday_data.featureid = mp.$entity_pkcol ";
    $q .= "     and maxday_data.entity_type = '$this->ts_entity_type' ";
    $q .= " ) ";
    $features = implode(", ", $this->featureid);
    $q .= " where mp.$entity_pkcol in ($features) ";
    if ($this->singular) {
      $q .= " limit 1 ";
    }
    $this->query = $q;
    //dpm($this->query, 'query');
    return TRUE;
  }
  
  function getFormEntityMapData(array $form_entity_map) {
    // @todo: this is still under development
    // uses entity_map to handle all inserts and updates
    // set up initial state of form_entity_map with entity default 
    // then we will go through and see if we can retrieve the entities 
    // in question based on those defaults
    $this->FormEntityMap($form_entity_map, $this->entity_defaults);
    foreach ($form_entity_map as $config) {
      $values = array();
      if (!isset($config['bundle'])) {
        $config['bundle'] = null;
      }
      $entity_type = $config['entity_type'];
      $bundle = $config['bundle'];
      // is this an edit or insert?
      // load the key
      $pk = $this->HandleFormMap($config['entity_key'], $record_group);
      // load the values array
      $values = array();
      foreach ($config['fields'] as $key => $map) {
        if ($map['value_src_type']) {
          $values[$key] = $this->HandleFormMap($map, $record_group);
        } else {
          // @todo - throw an error or alert about malformed entry
        }
      }
      if ($pk) {
        // PK set, so this is an update
        $e = entity_load_single($entity_type, $pk);
      } else {
        // no PK set, so this is an insert or a field query
        // if all fields in the array query_fields are present or not_null setting = FALSE
        // then we do an EFQ, otherwise we create
        $values['bundle'] = $bundle;
        $e = entity_create($entity_type, $values);
      }
      if ($e) {
        //stash the desired parts of this in the data array with appropriate keys for use in the form
      }
    }
  }
  
  function getData() {
    $form_entity_map = array();
    
    $this->data = array();
    //get the 
    $q = db_query($this->query);
    foreach ($q as $prow) {
      $this->data[] = $prow;
    }
    //dpm($this->data,'data');
  }
  
  public function formRowDefaults(&$rowform, $row) {
    // Row Record:
    //     featureid |       tstime        |      tsendtime      | meterloc_varid | meterloc_tid | meterloc_units | meterloc_tscode | method_varid | method_tid | method_units | method_tscode | maxday_varid | maxday_tid | maxday_tsvalue | maxday_tscode | maxday_units | maxday_tstime
    $rowform['featureid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->featureid,
    );
    // shared by method and meterloc
    // date-time
    $yr = $this->year;
    $rowform['tstime'] = array(
      '#default_value' => empty($row->tstime) ? strtotime("$yr/01/01") : $row->tstime,
      '#type' => 'hidden',
    );
    $rowform['tsendtime'] = array(
      '#default_value' => empty($row->tsendtime) ? strtotime("$yr/12/31") : $row->tsendtime,
      '#type' => 'hidden',
    );
    $rowform['method_tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->method_tid,
    );
    $rowform['method_varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->method_varid,
    );
    $methods = array(
      'E' => 'Estimated',
      'M' => 'Metered',
    );
    $rowform['method_tscode'] = array(
      '#field_prefix' => t('Metering Method'),
      '#type' => 'select',
      '#options' => $methods,
      '#default_value' => $row->method_tscode,
    );
    $rowform['meterloc_tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->meterloc_tid,
    );
    $rowform['meterloc_varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->meterloc_varid,
    );
    $meterlocs = array(
      'C' => 'Customer',
      'S' => 'Source',
    );
    $rowform['meterloc_tscode'] = array(
      '#field_prefix' => t('Meter Location'),
      '#type' => 'select',
      '#options' => $meterlocs,
      '#default_value' => $row->meterloc_tscode,
    );
    //dpm($this,'this');
    if ( (trim($this->year) == '') or ($this->year == 0)or ($this->year == NULL)) {
      $this->year = $row->maxday_tstime ? date('Y', $row->maxday_tstime) : $this->entity_defaults['year'];
    }
    $months = array();
    for ($i = 1; $i <= 12; $i++) {
      //drupal_set_message("strtotime($this->year/$i/01: " . strtotime("$this->year/$i/01"));
      $months[strtotime("$this->year/$i/01")] = date('F',strtotime("$this->year/$i/01"));
    }
    //dpm($months,'months');
    $rowform['maxday_tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->maxday_tid,
    );
    $rowform['maxday_varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->maxday_varid,
    );
    $rowform['maxday_tstime'] = array(
      '#field_prefix' => t('Month of Max Day'),
      '#type' => 'select',
      '#options' => $months,
      '#default_value' => $row->maxday_tstime,
    );
    $rowform['maxday_tsvalue'] = array(
      '#field_prefix' => "Max Day",
      '#field_suffix' => "$row->maxday_units",
      '#type' => 'textfield',
      //'#attributes' => array('disabled' => 'disabled'),
      '#default_value' => empty($row->maxday_tsvalue) ? 0.0 : $row->maxday_tsvalue,
      '#required' => TRUE,
      '#size' => 8,
      '#element_validate' => array('element_validate_number'),
    );
    
    $this->formRowVisibility($rowform, $row);
    
    // need to spoof a form_state for the row to properly load attached fields
    
  }
  
  public function buildOptionsForm(&$form, $form_state) {
    // Form for configuration when adding to interface
    //   public function buildOptionsForm(&$form, FormStateInterface $form_state) {
    // when we go to D8 this will be relevant
    // until then, we use the old school method
    parent::buildOptionsForm($form, $form_state);
    $val = token_replace($this->conf['display']['properties'][$token][$key], array(), array('clear'=>TRUE));
    // we may total over-ride this, but use some of the other guts to do querying
  }
  
  public function entityOptions(&$form, $form_state) {
    parent::entityOptions($form, $form_state);
    
    $form['entity_settings'][$this->groupname]['featureid'] = array(
      '#title' => t('Feature IDs'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['featureid']) > 0) ? $this->conf['featureid'] : NULL,
      '#description' => t('What entity id to retrieve TS values for.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    //dpm($form['entity_settings'], 'form');
    // over-ride parent form where needed
    $unsets = array('vocabulary', 'id', 'starttime', 'endtime', 'dh_link_admin_timeseries', 'varid');
    foreach ($unsets as $thisvar) {
      unset($form['entity_settings'][$this->groupname][$thisvar]);
    }
    $form['entity_settings'][$this->groupname]['maxday_varkey'] = array(
      '#title' => t('Variables'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['maxday_varkey']) > 0) ? $this->conf['maxday_varkey'] : NULL,
      '#description' => t('What varkey to use for Max-Day info (tokens ok).'),
      '#size' => 12,
      '#required' => FALSE,
    );
    $form['entity_settings'][$this->groupname]['method_varkey'] = array(
      '#title' => t('Metering Method Variable'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['method_varkey']) > 0) ? $this->conf['method_varkey'] : NULL,
      '#description' => t('What varkey to use for metering method storage.'),
      '#size' => 12,
      '#required' => FALSE,
    );
    $form['entity_settings'][$this->groupname]['meterloc_varkey'] = array(
      '#title' => t('Metering Location Variable'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['meterloc_varkey']) > 0) ? $this->conf['meterloc_varkey'] : NULL,
      '#description' => t('What varkey to use for metering location storage.'),
      '#size' => 12,
      '#required' => FALSE,
    );
    $form['entity_settings'][$this->groupname]['year'] = array(
      '#title' => t('Year'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['varkey']) > 0) ? $this->conf['year'] : NULL,
      '#description' => t('What year to report data (tokens ok).'),
      '#size' => 12,
      '#required' => FALSE,
    );
    $entities = entity_get_info();
    $form['entity_settings'][$this->groupname]['ts_entity_type'] = array(
      '#title' => t('Entity Type'),
      '#type' => 'select',
      '#options' => array_combine( array_keys($entities) , array_keys($entities) ),
      '#default_value' => isset($this->ts_entity_type) ? $this->ts_entity_type : 'dh_feature',
      '#description' => t('Entity Type'),
      '#required' => TRUE,
    );
  }
  
  public function FormEntityMap(&$form_entity_map = array(), $row = array()) {
    // @todo - create stub for this in parent class
    // the rate
    $form_entity_map['method'] = array(
      'entity_type' => 'dh_timeseries',
      'entity_class' => 'entity', // entity, entityreference, field
      'description' => 'Metering Method.',
      'bundle' => 'dh_timeseries',
      'debug' => FALSE,
      'notnull_fields' => array('tsvalue'),
      'entity_key' => array(
        'fieldname'=> 'tid',
        'value_src_type' => 'form_key', 
        'value_val_key' => 'method_tid', 
      ),
      'handler' => '', // NOT USED YET - could later add custom functions
      'fields' => array(
        // field_name - name in the destination entity 
        // field_type - type of data - valid values are property and field  
        // value_src_type - type of  
        // value_src_type - form_field, EntityFieldQuery, 
          // token, constant, env (environment var)
        'featureid' => array(
          'fieldname'=> 'featureid',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'featureid', 
        ),
        'entity_type' => array(
          'fieldname'=> 'entity_type',
          'field_type'=> 'property', 
          'value_src_type' => 'constant', 
          'value_val_key' => $this->ts_entity_type, 
        ),
        'varid' => array(
          'fieldname'=> 'varid', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'method_varid', 
        ),
        'tstime' => array(
          'fieldname'=> 'tstime', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'tstime', 
        ),
        'tscode' => array(
          'fieldname'=> 'tscode', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'method_tscode', 
        ),
        'tsvalue' => array (
          'fieldname'=> 'tsvalue',
          'field_type'=> 'property', 
          'value_src_type' => 'constant', 
          'value_val_key' => NULL, 
        ),
      ),
      'resultid' => 'method',
    );
    $form_entity_map['meterloc'] = array(
      'entity_type' => 'dh_timeseries',
      'entity_class' => 'entity', // entity, entityreference, field
      'description' => 'Metering Method.',
      'bundle' => 'dh_timeseries',
      'debug' => FALSE,
      'notnull_fields' => array('tsvalue'),
      'entity_key' => array(
        'fieldname'=> 'tid',
        'value_src_type' => 'form_key', 
        'value_val_key' => 'meterloc_tid', 
      ),
      'handler' => '', // NOT USED YET - could later add custom functions
      'fields' => array(
        // field_name - name in the destination entity 
        // field_type - type of data - valid values are property and field  
        // value_src_type - type of  
        // value_src_type - form_field, EntityFieldQuery, 
          // token, constant, env (environment var)
        'featureid' => array(
          'fieldname'=> 'featureid',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'featureid', 
        ),
        'entity_type' => array(
          'fieldname'=> 'entity_type',
          'field_type'=> 'property', 
          'value_src_type' => 'constant', 
          'value_val_key' => $this->ts_entity_type, 
        ),
        'varid' => array(
          'fieldname'=> 'varid', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'meterloc_varid', 
        ),
        'tstime' => array(
          'fieldname'=> 'tstime', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'tstime', 
        ),
        'tscode' => array(
          'fieldname'=> 'tscode', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'meterloc_tscode', 
        ),
        'tsvalue' => array (
          'fieldname'=> 'tsvalue',
          'field_type'=> 'property', 
          'value_src_type' => 'constant', 
          'value_val_key' => NULL, 
        ),
      ),
      'resultid' => 'meterloc',
    );
    $form_entity_map['maxday'] = array(
      'entity_type' => 'dh_timeseries',
      'entity_class' => 'entity', // entity, entityreference, field
      'description' => 'Metering Method.',
      'bundle' => 'dh_timeseries',
      'debug' => FALSE,
      'notnull_fields' => array('tsvalue'),
      'entity_key' => array(
        'fieldname'=> 'tid',
        'value_src_type' => 'form_key', 
        'value_val_key' => 'maxday_tid', 
      ),
      'handler' => '', // NOT USED YET - could later add custom functions
      'fields' => array(
        // field_name - name in the destination entity 
        // field_type - type of data - valid values are property and field  
        // value_src_type - type of  
        // value_src_type - form_field, EntityFieldQuery, 
          // token, constant, env (environment var)
        'featureid' => array(
          'fieldname'=> 'featureid',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'featureid', 
        ),
        'entity_type' => array(
          'fieldname'=> 'entity_type',
          'field_type'=> 'property', 
          'value_src_type' => 'constant', 
          'value_val_key' => $this->ts_entity_type, 
        ),
        'varid' => array(
          'fieldname'=> 'varid', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'maxday_varid', 
        ),
        'tstime' => array(
          'fieldname'=> 'tstime', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'maxday_tstime', 
        ),
        'tsvalue' => array (
          'fieldname'=> 'tsvalue',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'maxday_tsvalue', 
        ),
      ),
      'resultid' => 'maxday',
    );
  }
}

?>
