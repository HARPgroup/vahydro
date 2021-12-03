<?php

module_load_include('inc', 'dh_wsp', 'dh_wsp.widgets');

class DHMonthlyEvent extends dhTimeSeriesGroupPluggable {
  // @todo:
  //  save handlers
  //  formRowDefaults
  // viewBlock method
  var $event_id = FALSE;
  var $year;
  var $varkey;
  var $ann_varkey;
  var $save_method = 'form_entity_map';
  var $groupname = 'monthly_data';
  var $group_title = 'Monthly Data';
  var $group_description = 'Grid of monthly data for year indicated and selected variables.';
  var $entity_tokens = array('year', 'varkey', 'featureid', 'entity_type', 'ann_varkey');
  
  public function __construct($conf = array()) {
    parent::__construct($conf);
  }
  
  public function applyEntityTokens() {
    parent::applyEntityTokens();
  }
  
  public function applySettings() {
    parent::applySettings();
    // calls again because headers depend on year submitted
    if ( (trim($this->year) == '') or ($this->year == 0)) {
      $this->year = $this->entity_defaults['year'];
    }
    // be cool with a date and just extract the year
    list($this->year) = explode('-', $this->year);
    $this->headerDefaults();
  }
  
  public function entityDefaults() {
    parent::entityDefaults();
    // HEADERS - sets before calling parent 
    $this->entity_defaults['varkey'] = 'wd_mgm';
    $this->entity_defaults['ann_varkey'] = 'wd_mgy';
    $this->entity_defaults['groupname'] = 'monthly_data';
    $this->save_method = 'form_entity_map';
  }
  
  public function getDefaultYear() {
    $mo = date('n');
    $defyear = date('Y');
    if ($mo < 8) {
      $defyear = $defyear - 1;
    }
    return $defyear;
  }

  function submitForm(array &$form, $form_state) {
    parent::submitForm($form, $form_state);
  }

  public function headerDefaults() {
    $this->entity_defaults['year'] = $this->getDefaultYear();
    parent::headerDefaults();
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
  
  public function buildForm(&$form, &$form_state) {
    // we can put some things in here if we wish to customize display
    parent::buildForm($form, $form_state);
	
  }
  
  function prepareQuery() {
    $this->applyEntityTokens();
    $this->applySettings();
    if (count($this->featureid) == 0) {
      // @todo: proper error message here 
      return FALSE;
    }
    $ei = $this->getTSEntityInfo();
    //dpm($ei,'e info');
    $entity_pkcol = $ei['entity keys']['id'];
    $entity_pkcol = 'hydroid';
    $entity_tbl = $ei['base table'];
    // get app plan adminreg id
    // get linked chems
    // get rate group for each chem
      // varkey = agchem_rate_group
      // propcode = vocab of rate group: agchem_event_lbs, agchem_event_oz
    // get individual components of application
      // datatype = rate
      // datatype = amount
    // iterate through refs
    $q = "  select mp.$entity_pkcol as featureid, ";
    $q .= "   a.thisyear, b.thismonth, ";
    $q .= "   extract (epoch from to_timestamp(";
    $q .= "     a.thisyear || '-' || b.thismonth || ";
    $q .= "     '-' || 1, 'YYYY-MM-DD') ";
    $q .= "   ) as tstime, ";
    $q .= "   v.hydroid as varid, c.tid, v.varunits as units, ";
    $q .= "   c.tsvalue as tsvalue, d.tsvalue as tsvalue_1, ";
    $q .= "   e.tsvalue as tsvalue_2 ";
    $q .= " from $entity_tbl as mp  ";
    $q .= " left outer join ";
    $q .= " ( ";
    $q .= "    select $this->year::integer as thisyear ";
    $q .= " ) as a ";
    $q .= " on (1 = 1) ";
    $q .= " left outer join (    ";
    $q .= " select generate_series as thismonth from generate_series(1,12) ";
    $q .= " ) as b ";
    $q .= " on (1 = 1) ";
    $q .= " left outer join dh_variabledefinition as v  ";
    $q .= " on (v.varkey = '$this->varkey') ";
    $q .= " left outer join dh_timeseries as c ";
    $q .= " on ( ";
    $q .= "   c.varid = v.hydroid  ";
    $q .= "     and to_timestamp(c.tstime) = to_timestamp(a.thisyear || '-' || ";
    $q .= " b.thismonth || '-' || 1, 'YYYY-MM-DD' ) ";
    $q .= "     and c.featureid = mp.$entity_pkcol ";
    $q .= "     and c.entity_type = '$this->ts_entity_type' ";
    $q .= " ) ";
    $q .= " left outer join dh_timeseries as d ";
    $q .= " on ( ";
    $q .= "   d.varid = v.hydroid ";
    $q .= "     and to_timestamp(d.tstime) = to_timestamp((a.thisyear -1) ";
    $q .= "       || '-' || b.thismonth || '-' || 1, 'YYYY-MM-DD')";
    $q .= "     and d.featureid = mp.$entity_pkcol";
    $q .= "     and d.entity_type = 'dh_feature'";
    $q .= " )";
    $q .= " left outer join dh_timeseries as e";
    $q .= " on (";
    $q .= "   e.varid = v.hydroid ";
    $q .= "     and to_timestamp(e.tstime) = to_timestamp((a.thisyear) - 2 ";
    $q .= "       || '-' || b.thismonth || '-' || 1, 'YYYY-MM-DD')";
    $q .= "     and e.featureid = mp.$entity_pkcol";
    $q .= "     and e.entity_type = 'dh_feature'";
    $q .= " )";
    $features = implode(", ", $this->featureid);
    $q .= " where mp.$entity_pkcol in ($features) ";
    $q .= " and v.varkey = '$this->varkey' ";
    $q .= " order by a.thisyear, b.thismonth";
    $this->query = $q;
    //dpm($this->query, 'query');
    return TRUE;
  }
  
  function getData() {
    if (!isset($this->query) or !$this->query) {
      // malformed or non existent query
      return FALSE;
    }
    $this->data = array();
    //get the info linked to this event
    $q = db_query($this->query);
    //dpm($q, "initial data");
    foreach ($q as $tsrow) {
      //dpm($tsrow,'starting value');
      if ($tsrow->tid == NULL) {
        // this is an insert request
        //dpm((array)$tsrow, "Creating blank");
        $ts_entity = entity_create($this->base_entity_type, (array)$tsrow);
      } else {
        $entities = entity_load($this->base_entity_type, array($tsrow->tid));
        $ts_entity = array_shift($entities);
      }
      $ts_entity->ts_entity_type = $ts_entity->entity_type;
      $ts_entity->year = $tsrow->thisyear;
      $ts_entity->thisyear = $tsrow->thisyear;
      $ts_entity->month = $tsrow->thismonth;
      $ts_entity->thismonth = $tsrow->thismonth;
      $ts_entity->tsvalue = $tsrow->tsvalue;
      $ts_entity->tsvalue_1 = $tsrow->tsvalue_1;
      $ts_entity->tsvalue_2 = $tsrow->tsvalue_2;
      $ts_entity->units = $tsrow->units;
      //dpm($ts_entity,'final');
      $this->data[] = $ts_entity;
    }
    /*
    foreach ($q as $prow) {
      // while we go through this we look for duplicates
      // and add an error in the timeseries table for the admin
      // to take a look
       if ($prow->tid == NULL) {
        // this is an insert request
        // not sure if we do anything different between these two cases?
        // maybe check here for default variables?
        //dpm($prow, "Creating blank");
        $this->data[] = $prow;
      } else {
        // not sure if we do anything different between these two cases?
        // maybe check here for default variables?
        $this->data[] = $prow;
      }
    }
    */
  }
  
  public function viewBlock() {
    // this base class does nothing but show block in this->data, all data pop will be done by sub-classes.
    $this->applyEntityTokens();
    $this->applySettings();
    $prop = NULL;
    $rows = array();
    if (!(count($this->data) > 0)) {
      return '';
    }
    $out = '';
    return $out;
  }
  
  public function formRowDefaults(&$rowform, $row) {
    // Row Record:
    //    planid, chemid, name, 
    //    rate_pid, rate_varid, rate_propvalue,
    //    amount_pid, amount_varid, amount_propvalue
    $pc = $this->conf['display']['properties'];
    //dpm($pc, "Prop conf");
    $fc = $this->conf['display']['fields'];
    $rowform['tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->tid,
    );
    $rowform['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->varid,
    );
    $rowform['featureid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->featureid,
    );
    $rowform['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $this->ts_entity_type,
    );
    $rowform['tstime'] = array(
      '#coltitle' => 'Month',
      '#prefix' => !empty($row->tstime) ? date('M', $row->tstime) : 'unk',
      '#type' => 'hidden',
      '#default_value' => $row->tstime,
    );
    // date-time
    $yr = $this->year;
    $rowform['tsvalue'] = array(
      '#coltitle' => $yr,
      '#type' => 'textfield',
      //'#attributes' => array('disabled' => 'disabled'),
      '#default_value' => empty($row->tsvalue) ? 0.0 : $row->tsvalue,
      '#required' => TRUE,
      '#size' => 8,
      '#element_validate' => array('element_validate_number'),
    );
    $rowform['tsvalue_1'] = array(
      '#coltitle' => $yr - 1,
      '#markup' => empty($row->tsvalue_1) ? 0.0 : $row->tsvalue_1,
    );
    $rowform['tsvalue_2'] = array(
      '#coltitle' => $yr - 2,
      '#markup' => empty($row->tsvalue_2) ? 0.0 : $row->tsvalue_2,
    );
    
    $rowform['units'] = array(
      '#coltitle' => 'Units',
      '#markup' => empty($row->units) ? '' : $row->units,
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
    //dpm($form['entity_settings'][$this->groupname], 'form');
    // over-ride parent form where needed
    $unsets = array('vocabulary', 'id', 'starttime', 'endtime', 'dh_link_admin_timeseries', 'varid');
    foreach ($unsets as $thisvar) {
      unset($form['entity_settings'][$this->groupname][$thisvar]);
    }
    $form['entity_settings'][$this->groupname]['varkey'] = array(
      '#title' => t('Variables'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['varkey']) > 0) ? $this->conf['varkey'] : NULL,
      '#description' => t('What varkey to retrieve Monthly TS values for (tokens ok).'),
      '#size' => 12,
      '#required' => FALSE,
    );
    $form['entity_settings'][$this->groupname]['ann_varkey'] = array(
      '#title' => t('Annutal Total Variable'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['ann_varkey']) > 0) ? $this->conf['ann_varkey'] : NULL,
      '#description' => t('What varkey to assign Annual total (tokens ok, if blank no annual summary will be created).'),
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
    $form_entity_map['ts_monthly'] = array(
      'entity_type' => 'dh_timeseries',
      'entity_class' => 'entity', // entity, entityreference, field
      'description' => 'Reported volume.',
      'bundle' => 'dh_timeseries',
      'debug' => FALSE,
      'notnull_fields' => array('tsvalue'),
      'entity_key' => array(
        'fieldname'=> 'tid',
        'value_src_type' => 'form_key', 
        'value_val_key' => 'tid', 
      ),
      'handler' => '', // NOT USED YET - could later add custom functions
      'fields' => array(
        // field_name - name in the destination entity 
        // value_src_type - type of  
        // value_src_type - form_field, EntityFieldQuery, 
          // token, constant, env (environment var)
        'featureid' => array(
          'fieldname'=> 'featureid',
          'value_src_type' => 'form_key', 
          'value_val_key' => 'featureid', 
        ),
        'entity_type' => array(
          'fieldname'=> 'entity_type',
          'value_src_type' => 'form_key', 
          'value_val_key' => 'entity_type', 
        ),
        'varid' => array(
          'fieldname'=> 'varid', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'varid', 
        ),
        'tstime' => array(
          'fieldname'=> 'tstime', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'tstime', 
        ),
        'tsvalue' => array (
          'fieldname'=> 'tsvalue',
          'value_src_type' => 'form_key', 
          'value_val_key' => 'tsvalue', 
        ),
      ),
      'resultid' => 'wd_amount',
    );
  }

}

class DHMonthlyReportingEvent extends DHMonthlyEvent {
  // expects this to have an entity reference linking MP 
  // to parent, with an extra config variable to hold the summed value for 
  // parent report
  
  public function entityOptions(&$form, $form_state) {
    parent::entityOptions($form, $form_state);
    // adds place to hold parent variable for summary
    $form['entity_settings'][$this->groupname]['ann_varkey'] = array(
      '#title' => t('Annual Total Variable'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['ann_varkey']) > 0) ? $this->conf['ann_varkey'] : NULL,
      '#description' => t('What varkey to assign Annual total (tokens ok, if left blank no annual summary will be created).'),
      '#size' => 12,
      '#required' => FALSE,
    );
  }

  public function buildForm(&$form, &$form_state) {
    // we can put some things in here if we wish to customize display
    parent::buildForm($form, $form_state);
	$form['tsvalue']['#size'] = 12;
  }
  
  function submitForm(array &$form, $form_state) {
    parent::submitForm($form, $form_state);
    $this->updateAnnualTotal($form_state);
  }

  function updateAnnualTotal($form_state) {
    // two tasks here:
    // 1. Update annual total variable for this MP
    // 2. (may defer?) Update annual total variable for the Facility this MP belongs to

    $this->applyEntityTokens();
    $this->applySettings();
    if (count($this->featureid) == 0) {
      // @todo: proper error message here 
      return FALSE;
    }
    if ( (trim($this->year) == '') or ($this->year == 0)) {
      $this->year = $this->entity_defaults['year'];
    }
    if (trim($this->ann_varkey) == '') {
      return FALSE;
    }
    // be cool with a date and just extract the year
    list($this->year) = explode('-', $this->year);
    // get sum
    $tstime = strtotime($this->year . '-01-01');
    $tsendtime = strtotime($this->year . '-12-31');
    $total = 0;
    foreach ($form_state['values'][$this->groupname] as $thisval) {
      $total += $thisval['tsvalue'];
    }
    // this is now performed at the monthly value plugin level.
    // verify that this is doing ok and delete
    /*
    $ei = $this->getTSEntityInfo();
    $this->featureid = array_shift($this->featureid);
    $entity_pkcol = $ei['entity keys']['id'];
    $entity_pkcol = 'hydroid';
    $entity_tbl = $ei['base table'];
    $efq = new EntityFieldQuery(); 
    $varinfo = dh_vardef_info($this->ann_varkey);
    if (isset($varinfo->hydroid)) {
      $efq->entityCondition('entity_type', 'dh_timeseries');
      $efq->propertyCondition('entity_type', $entity_tbl);
      $efq->propertyCondition('varid', $varinfo->hydroid);
      $efq->propertyCondition('featureid', $this->featureid);
      $efq->propertyCondition('tstime', $tstime);
      $efq->propertyCondition('tsendtime', $tsendtime);
      $result = $efq->execute();
      if (isset($result['dh_timeseries'])) {
        $ann_rez = array_shift($result['dh_timeseries']);
        $ann_entity = entity_load_single('dh_timeseries', $ann_rez->tid);
      } else {
        // create a new one
        $conf = array(
          'entity_type' => $entity_tbl,
          'varid' => $varinfo->hydroid,
          'featureid' => $this->featureid,
          'tstime' => $tstime,
          'tsendtime' => $tsendtime,
        );
        $ann_entity = entity_create('dh_timeseries', $conf);
      }
      if (is_object($ann_entity)) {
        $ann_entity->tsvalue = $total;
        $ann_entity->save();        
      }
    }
    //dpm($this->query, 'query');
    */
  }
}

class DHGWPermitMonthlyReportingEvent extends dhTimeSeriesGroup {
  var $year;
  var $varkey;
  var $ann_varkey;
  //var $save_method = 'form_entity_map';
  var $groupname = 'monthly_data';
  var $group_title = 'Monthly Data';
  var $allprops = TRUE; // this allows us to add properties such as net_wd
  var $group_description = 'Grid of monthly data for year indicated and selected variables.';
  var $entity_tokens = array('year', 'varkey', 'featureid', 'entity_type', 'ann_varkey');
  
  function prepareQuery() {
    //dpm($this->featureid, 'prepareQuery() called');
    if (count($this->featureid) == 0) {
      // @todo: proper error message here 
      return FALSE;
    }
    $ei = $this->getTSEntityInfo();
    //dpm($ei,'e info');
    $entity_pkcol = $ei['entity keys']['id'];
    $entity_pkcol = 'hydroid';
    $entity_tbl = $ei['base table'];
    $q = "  select mp.$entity_pkcol as featureid, ";
    $q .= "   a.thisyear, b.thismonth, ";
    $q .= "   extract (epoch from to_timestamp(";
    $q .= "     a.thisyear || '-' || b.thismonth || ";
    $q .= "     '-' || 1, 'YYYY-MM-DD') ";
    $q .= "   ) as tstime, ";
    $q .= "   v.hydroid as varid, c.tid, v.varunits as units, ";
    $q .= "   c.tsvalue as tsvalue ";
    $q .= " from $entity_tbl as mp  ";
    $q .= " left outer join ";
    $q .= " ( ";
    $q .= "    select $this->year::integer as thisyear ";
    $q .= " ) as a ";
    $q .= " on (1 = 1) ";
    $q .= " left outer join (    ";
    $q .= " select generate_series as thismonth from generate_series(1,12) ";
    $q .= " ) as b ";
    $q .= " on (1 = 1) ";
    $q .= " left outer join dh_variabledefinition as v  ";
    $q .= " on (v.varkey = '$this->varkey') ";
    $q .= " left outer join dh_timeseries as c ";
    $q .= " on ( ";
    $q .= "   c.varid = v.hydroid  ";
    $q .= "     and to_timestamp(c.tstime) = to_timestamp(a.thisyear || '-' || ";
    $q .= " b.thismonth || '-' || 1, 'YYYY-MM-DD' ) ";
    $q .= "     and c.featureid = mp.$entity_pkcol ";
    $q .= "     and c.entity_type = '$this->ts_entity_type' ";
    $q .= " ) ";
    $features = implode(", ", $this->featureid);
    $q .= " where mp.$entity_pkcol in ($features) ";
    $q .= " and v.varkey = '$this->varkey' ";
    
    if (in_array($this->quarter, array(1,2,3,4))) {
      $qs = ($this->quarter - 1) * 3 + 1;
      $qe = $this->quarter * 3 + 1;
      $q .= " and b.thismonth >= " . $qs ;
      $q .= " and b.thismonth < " . $qe;
    }
    
    $q .= " order by a.thisyear, b.thismonth";
    $this->query = $q;
    dpm($this->query, 'query');
    return TRUE;
  }
  
  public function formRowDefaults(&$rowform, $row) {
    parent::formRowDefaults($rowform, $row);
    
    $rowform['tsvalue']['#coltitle'] = 'Meter Reading';
    $rowform['tscode']['#coltitle'] = 'Reading Type';
    $rowform['tsvalue']['#required'] = FALSE;
    $rowform['tstime'] = array(
      '#coltitle' => 'Month',
      '#prefix' => !empty($row->tstime) ? date('M', $row->tstime) : 'unk',
      '#type' => 'hidden',
      '#default_value' => $row->tstime,
    );
    $rowform['net_wd'] = array(
      '#type' => 'textfield',
      '#coltitle' => 'Total Withdrawn',
      '#default_value' => $row->net_wd,
    );
    /*
    // date-time
    // @todo: we should be able to 
    //   1. find the Plugin associated with this variable
    //   2. call the formRowEdit() method on this
    if (!in_array(get_class($row), array('dHTimeSeriesTable', 'dHProperties')) or empty($row->varid)) {
      $row = entity_create('dh_timeseries', array('varid' => dh_varkey2varid($this->varkey, TRUE), 'entity_type' => 'dh_feature', 'bundle'=>'dh_timeseries'));
      dpm($row,'blank row');
    }
    dh_variables_getPlugins($row);
    $handled = FALSE;
    foreach ($row->dh_variables_plugins as $plugin) {
      if (method_exists($plugin, 'formRowEdit')) {
        $plugin->formRowEdit($rowform, $row);
        //dpm($rowform,'rowform after plugin');
      }
    }
    dpm($row,'row');
    //dpm($rowform,'rowform after plugin');
    */
  }
  public function submitFormCustom(array &$form, $form_state) {
    //dpm($form_state, 'form_state');
    parent::submitFormCustom($form, $form_state);
  }
  
}

?>
