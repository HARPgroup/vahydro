<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHWaterDemandProjectionBase extends dHVariablePluginDefault {
  // The base class for projection values (not tables)
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    foreach ($this->hiddenFields() as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function hiddenFields() {
    return array('pid', 'varid', 'featureid', 'entity_type', 'bundle', 'propcode', 'dh_link_admin_pr_condition');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // special render handlers when displaying in a grouped property block
    $row->propvalue = number_format($row->propvalue, 3);
  }
  public function loadReplicantDeprecated($entity, $varkey, $repl_bundle = FALSE) {
    // @todo: remove this method after testing the loadReplicant() put on the base class
    // new version handles timeseries as well as properties
    // only do this for a property, not a time series
    
    if ($entity->entityType() == 'dh_properties') {
      $vars = dh_varkey2varid($varkey);
      $replicant_varid = array_shift($vars);
      $replicant_info = array(
        'featureid' => $entity->featureid,
        'entity_type' => $entity->entity_type,
        'bundle' => 'dh_properties',
        'varid' => $replicant_varid,
      );
      // *************************************************
      // Current MGY
      // *************************************************
      $replicant_prec = dh_get_properties($replicant_info, 'singular');
      if ($replicant_prec) {
        $rec = array_shift($replicant_prec['dh_properties']);
        $replicant_prop = entity_load_single('dh_properties', $rec->pid);
      } else {
        $replicant_prop = entity_create('dh_properties', $replicant_info);
      }
      //dpm($replicant_prop,'loaded replicant_prop');
      return $replicant_prop;
    }
    return FALSE;
  }
}

class dHWaterDemandProjection extends dHVarWithTableFieldBase {
  var $matrix = array();
  var $default_bundle = 'wsp_projection';
  var $matrix_field = 'field_projection_table';
  
  public function hiddenFields() {
    return array(
      'pid', 'varid', 'featureid', 'entity_type', 'bundle', 'dh_link_admin_pr_condition', 
      'field_prj_matrix', 
      'field_test_matrix', 
      'field_matrix'
    );
  }
  
  public function buildContent(&$content, &$entity, $view_mode) {
    // for use in views entity rendering
    // syntax explained: https://www.drupal.org/node/930760
    // may be able to use tokens as well: https://www.drupal.org/node/390482#token-current-date
    $feature = $this->getParentEntity($entity);
    $hidden = array_keys($content);
    foreach ($hidden as $col) {
      $content[$col]['#type'] = 'hidden';
    }
    switch($view_mode) {
      case 'plugin':
        $this->addContentPercents($content, $entity);
      break;
      default:
      case 'full':
        $content['entity_name']['#markup'] = $feature->name . ' demand projection modified on ' . date('Y-m-d', $feature->modified); 
        // see docs for drupal function l() for link config syntax
        $content['link'] = array(
          '#type' => 'link',
          '#prefix' => '&nbsp;',
          '#title' => 'View',
          '#href' => 'ows-'. $feature->bundle . '-' . $feature->ftype . '-info/' . $feature->adminid,
        );
        $this->addContentPercents($content, $entity);
      break;
    }
    //dpm($content, "Proj table content");
  }
  
  public function addContentPercents(&$content, $entity) {
    $content['field_projection_table'][0]['#header']['col_0']['data'] = "Category | Year";
    $content['field_projection_table'][0]['#header']['trend'] = array(
      'data' => 'Trend',
      'class' => array('row_0', 'col_0')
    );
    foreach ($content['field_projection_table'][0]['#rows'] as $key => $row) {
      $cat = $content['field_projection_table'][0]['#rows'][$key]['col_0']['data'];
      $factor = $this->dh_getValue($entity, FALSE, FALSE, array('category' => $cat));
      $pct = empty($factor) ? 'NA' : round(($factor - 1.0) * 100.0,2) . "%";
      $content['field_projection_table'][0]['#rows'][$key]['trend'] = array(
        'data' => $pct,
        'class' => array($key, 'col_0')
      );
    }
  }
  
  // @todo: integrate this to add commas in number fields.
  public function applyFormat(&$content, $row, $col, $type, $config) {
    $format_defaults = array(
      'number_format' => array(
        'decimals' => 0,
        'dec_point' => 0,
        'thousands_sep' => 0,
      ),
    );
    $orig = $content['field_projection_table'][0]['#rows'][$row][$col]['data'];
    $content['field_projection_table'][0]['#rows'][$row][$col]['data'] = 
      number_format($orig, $config['decimals'], $config['dec_point'], $config['thousands_sep'])
    ;
  }
  
  public function formRowEdit(&$form, $entity) {
    // apply custom settings here
    // note: when using '+' to combine arrays, the key-value pairs in the 1st will
    //       take priority over the 2nd, so this is essentially a UNION, with only new info
    //       added by the keys in the 2nd and no over-write of values.
    // $form syntax: https://api.drupal.org/api/drupal/developer%21topics%21forms_api_reference.html/7.x
    $plan = $this->getParentEntity($entity);
    $base_year = date('Y', $plan->startdate);
    //dpm($entity,'proj prop');
    $form['proptext']['und'][0]['value']['#title'] = 'Comments on Projection Calculations';
    $date_format = 'Y';
    $form['related_plan'] = array(
      '#markup' => $plan->name . " with a starting year of $base_year",
      '#weight' => -1,
    );
    $form['startdate'] = array(
      //'#type' => 'date_popup',
      '#title' => 'Custom Year',
      '#type' => 'date_select',
      '#date_year_range' => '-10:+5',
      '#date_format' => $date_format,
      '#default_value' => empty($entity->startdate)
        ? '' 
        : date($date_format,$entity->startdate),
      '#description' => t('Override start year for this projection table, used as the start date of "Current Demand" for all demand projections linked to this table. Leave blank to default to plan system.'),
      //'#required' => TRUE,
    );
    // set row_0 to read only in first column, other read-write
    $element = &$this->getTablefieldElementRef($form, $this->matrix_field);
    // make the first column read-only, since these are fixed by WSP Planning Reg
    // DO NOT COMBINE this with the field setting to "Lock Default Values".
    //   - because the way that tablefield evaluates lock default values, it will
    //     not respect existing row or column key pairs, thus if the default 
    //     row and column headers are not in the same order as those in an existing 
    //     entity, the result is to rearrange the colums/rows causing potentially mismatched 
    //     data.
    $this->lockColumn($element, 0);
    $this->lockRow($element, 0);
    // Now, hide the old table
    foreach ($this->hiddenFields() as $hide_this) {
      $form[$hide_this]['#type'] = 'hidden';
    }
  }
  
  // @todo: move this to the tablefield base class
  function lockRow(&$element, $i) {
    // $ii is the column to lock.
    list($rows, $cols) = $this->getTablefieldElementSize($element);
    for ($ii = 0; $ii < $cols; $ii++) {
      $instance_default = $element['tabledata']["row_$i"]["col_$ii"]['#default_value'];
        $element['tabledata']["row_$i"]["col_$ii"] = array(
          '#type' => 'value',
          '#value' => $instance_default,
        );
        // Display the default value, since it's not editable.
        $display = array();
        $display["col_$ii" . "_display"] = array(
          '#type' => 'item',
          '#title' => $instance_default,
          '#prefix' => '<td class="col-' . $ii . '">',
          '#suffix' => '</td>',
        );
        if ($i == 0) {
          // fancify the first row if locked
          $display["col_$ii" . "_display"]['#prefix'] = '<td class=" tablefield-row-0">';
        }
        $this->array_insert($element['tabledata']["row_$i"], $ii + 1, $display);
    }
  }
  
  // @todo: move this to the tablefield base class
  function lockColumn(&$element, $ii) {
    // $ii is the column to lock.
    list($rows, $cols) = $this->getTablefieldElementSize($element);
    for ($i = 0; $i < $rows; $i++) {
      $instance_default = $element['tabledata']["row_$i"]["col_$ii"]['#default_value'];
        $element['tabledata']["row_$i"]["col_$ii"] = array(
          '#type' => 'value',
          '#value' => $instance_default,
        );
        // Display the default value, since it's not editable.
        $display = array();
        $display["col_$ii" . "_display"] = array(
          '#type' => 'item',
          '#title' => $instance_default,
          '#prefix' => '<td class="col-' . $ii . '">',
          '#suffix' => '</td>',
        );
        if ($i == 0) {
          // fancify the first row if locked
          $display["col_$ii" . "_display"]['#prefix'] = '<td class=" tablefield-row-0">';
        }
        $this->array_insert($element['tabledata']["row_$i"], $ii + 1, $display);
    }
  }
  
  function array_insert(&$array, $position, $insert_array) { 
    $first_array = array_splice ($array, 0, $position); 
    $array = array_merge ($first_array, $insert_array, $array); 
  } 

  
  public function &getTablefieldElementRef(&$form, $field_name) {
    // sets the variable as a reference that will automatically modify the form element 
    return $form[$field_name]['und'][0]['tablefield'];
  }
  
  public function getTablefieldElementSize($element) {
    // sets the variable as a reference that will automatically modify the form element 
    $rebuild = $element['rebuild'];
    return array(
      $rebuild['count_rows']['#value'],
      $rebuild['count_cols']['#value'] 
    );
  }
  
  public function &getTablefieldFormCellRef(&$element, $cell_name) {
    // sets the variable as a reference that will automatically modify the form element 
    return $element[$cell_name];
  }
  
  public function setTablefieldFormCell(&$element, $cell_name, $cell_element) {
    // sets the variable as a reference that will automatically modify the form element 
    return $form[$field_name];
  }
  
  public function formRowSave(&$form_values, &$entity) {
    // handle the year selector
    dpm($form_values,'form values');
    if (!($form_values['startdate'] == NULL)) {
      $form_values['startdate'] = $form_values['startdate'] . "-01-01";
      $entity->startdate = dh_handletimestamp($form_values['startdate']);
    }
  }
  
  // *******************************************************************************
  // update() and insert() are called after the TS or prop entity is saved, which allows 
  // us to do things that require a final, saved object, such as insure we have a tid/pid
  
  public function update(&$entity) {
    // add a ts event to note a insert or edit
    $this->recordChange($entity);
    // pass updates to all objects linked to this.
    $this->updateLinked($entity);
  }
  
  public function insert(&$entity) {
    // add a ts event to note a insert or edit
    $this->recordChange($entity);
  }
  
  public function updateLinked(&$entity) {
    // @todo: put a stub for this in the base class
    // iterate through things linked to this and call a entity_load() and entity_save()
    // if they have behaviors that trigger some propagated changes, then great, otherwise
    // no change will occur.
    // Link propagation can ONLY flow from the target entity to the destination entity, for security
    // Link fields for propagation must be explicitly defined in the plugin def
    
    // Only do this if it is a property, since we can have timeseries record stuck in with the same varid
    // to record edits.  This should be changed, we should have specific variables to show edits in order 
    // to have time varying projections as TS records.
    if ($entity->entityType() == 'dh_properties') {
      module_load_include('module', 'dh');
      // this looks for properties that are eref'ed to this property
      $eref_config = array(
        'eref_fieldname' => 'field_linked_projection', 
        'entity_type' => 'dh_properties',
        'entity_id_name' => 'pid',
        'target_entity_id' => $entity->pid,
      );
      //dpm($eref_config,'eref_config');
      $refs = dh_get_reverse_erefs($eref_config);
      //dpm($refs,'refs');
      $i = 0;
      //error_log("Found linked objects: " . print_r($refs,1));
      foreach ($refs as $eid) {
        //error_log("Handling objects pid $eid: ");
        $linked = entity_load_single($eref_config['entity_type'], $eid);
        $i++;
        /*
        if ($i <= 2) {
          dpm($linked, 'linked');
          dpm(get_class_methods($linked),'methods');
        }
        */
        if (is_object($linked)) {
          entity_save($eref_config['entity_type'], $linked);
        }
      }
      
    }
  }
  
  public function recordChange(&$entity) {
    // add a ts event for this if this is a property
    // we must avoid doing this if it is a TS because we would create an endless recursion
    // @todo: move this to base class or module code
    // time resolutions:
    //   singular - only one ts event ever for this feature/varid combo
    //   tstime_singular - only onets event for this feature/varid/tstime combo
    //dpm($entity, 'entity');
    $feature = $this->getParentEntity($entity);
    if ($entity->entityType() == 'dh_properties') {
      $ts_rec = array(
        'varid' => $entity->varid,
        'tsvalue' => $entity->propvalue,
        'tscode' => 'inserted',
        //'tstime' => mktime(),
        'tstime' => $entity->modified,
        'featureid' => $entity->featureid,
        'entity_type' => $feature->entityType(),
      );
      dh_update_timeseries($ts_rec, 'tstime_singular');
    }
  }
  
  public function dh_getValue($entity, $ts = FALSE, $propname = FALSE, $config = array()) {
    // @todo: implement first 2 parameters $ts and $propname 
    // called by the entity's own om_getValue routines
    // entity checks for plugins, if they exists, it runs the plugins om_getValue routine, if not, it 
    // uses its default
    //dpm($entity, "Updating proj");
    $category = isset($config['category']) ? $config['category'] : 'Base Rate';
    $plan = $this->getParentEntity($entity);
    //dpm($plan, "source date");
    $base_year = ($entity->startdate === NULL) ? date('Y', $plan->startdate) : date('Y', $entity->startdate);
    $proj_year = date('Y', $plan->enddate);
    $base_year = isset($config['base_year']) ? $config['base_year'] : $base_year; 
    $proj_year = isset($config['proj_year']) ? $config['proj_year'] : $proj_year; 
      // note: the projection will look to it's parent entity for enddate, so if the 
      //   projection is located at a region, region enddate must be specified, if locality 
      //   then locality enddate must be specified - which should be no roblem since we will 
      //   enforce this programatically 
    
    // Load the Matrix from Tablefield 
    
    $tablefield = $entity->{$this->matrix_field}['und'][0];
    $tabledata = isset($tablefield['tablefield']) ? $tablefield['tablefield']['tabledata'] : $tablefield['tabledata']['tabledata'];
    $matrix = dh_tablefield_to_associative($tabledata);
    
    // @todo: delete these next few lines when certain that the old field_matrix 
    //        is well and truly gone.
    //$mm_matrix = matrix_field_to_assoc('field_matrix', $entity->field_matrix['und']); // populates this->matrix
    //dpm($matrix, 'new matrix');
    //dpm($mm_matrix,'old matrix');
    //dpm($category,'category');
    $row = isset($matrix[$category]) ? $matrix[$category] : array();
    if (empty(array_filter($row))) {
      //dpm($row,'empty or all null - returning FALSE');
      // returns false if there is no matching category or if all values are zero or null
      return FALSE;
    }
    // expects years: 2010, 2015, 2010, 2030, ...
    // with last column as Trend
    foreach ($row as $key => $value) {
      if (!is_numeric($key)) {
        continue;
      }
      $values[$key] = $value;
    }
    // interpolated lookup table
    $startval = $this->doLookup($values, $base_year, FALSE);
    $endval = $this->doLookup($values, $proj_year, FALSE);
    // defaults to the first and last 
    $startval = !($startval === FALSE) ? $startval : array_shift($values);
    $endval = !($endval === FALSE) ? $endval : array_pop($values);
    $endval = !empty($endval) ? $endval : $startval;
    
    switch ($entity->field_projection_type['und'][0]['value']) {
      case 'rate':
      // current: assumes final rate applies to entire period
      // @todo: iterate through decades in table, applying the rate 
      // so that intermediate rates are accounted for
        $factor = pow((1 + $endval),($proj_year - $base_year));
        //dsm("$category: $factor = pow((1 + $endval),($proj_year - $base_year));");
      break;

      case 'simple_rate':
        // takes percentile as simple change per year from baseline
        $factor =  1.0 + $endval * ($proj_year - $base_year);
        //dsm("$category: $factor =  1.0 + $endval * ($proj_year - $base_year);");
      break;
      
      case 'value':
        // a table of numbers
        $factor = ($startval <> 0) ? $endval / $startval : 1.0;
        //dsm("$category: $factor = ($startval <> 0) ? $endval / $startval : 1.0");
      break;
      
      default:
        $factor = 1.0;
      break;
      
    }
    return $factor;
  }
  
  public function tableDefault($entity) {
    // Returns associative array keyed table (like is used in OM)
    // This format is not used by Drupal however, so a translation 
    //   with tablefield_parse_assoc() is usually in order (such as is done in load)
    // set up defaults - we can sub-class this to handle each version of the model land use
    // This version is based on the Chesapeake Bay Watershed Phase 5.3.2 model land uses
    // this brings in an associative array keyed as $table[$luname] = array( $year => $area )
    $table = array();
    $table[] = array('Category', 2010, 2015,2020,2025,2030,2035,2040,2045,2050);
    $table[] = array('Base Rate', '', '','','','','','','','');
    $table[] = array('Residential', '', '','','','','','','','');
    $table[] = array('Com/Inst/LI', '', '','','','','','','','');
    $table[] = array('Heavy Industry', '', '','','','','','','','');
    $table[] = array('Military', '', '','','','','','','','');
    $table[] = array('Process Loss', '', '','','','','','','','');
    $table[] = array('Unaccounted Loss', '', '','','','','','','','');
    $table[] = array('Sales', '', '','','','','','','','');
    $table[] = array('Agriculture', '', '','','','','','','','');
    $table[] = array('Small SSU on GW', '', '','','','','','','','');
    $table[] = array('Large SSU', '', '','','','','','','','');
    $table[] = array('Other', '', '','','','','','','','');
    return $table;
  }
  
  function doLookup($values, $key, $default_value){
    $lukeys = array_keys($values);
    $luval = $default_value;
    for ($i=0; $i < (count($lukeys) - 1); $i++) {
      // need to handle blank cells. 
      //   - if lokey cell is blank, skip
      //   - if hikey cell is blank, increment until finding a non-blank entry
      $lokey = $lukeys[$i];
      if (empty($values[$lokey])) {
        continue;
      }
      $j = $i + 1;
      $hival = NULL;
      while ( (empty($values[$lukeys[$j]]) and $j <= (count($lukeys) - 1)) ) {
        // search for a non-null next key
        $j++;
      }
      // if no non-null hival, return
      if ($j > (count($lukeys) - 1)) {
        continue;
      }
      $hikey = $lukeys[$j];
      $loval = $values[$lokey];
      $hival = $values[$hikey];
      //dsm("Evaluating $key $lokey and $hikey w/ $loval - $hival");
      $minkey = min(array($lokey,$hikey));
      $maxkey = max(array($lokey,$hikey));
      if ( ($minkey <= $key) and ($maxkey >= $key) ) {
       $luval = $this->interpValue($key, $lokey, $loval, $hikey, $hival);
        //dsm("Found $key $minkey and $maxkey, luval = $luval ");
      }
    }
    //dpm($values, "Searching for $key in array, returning $luval");
    return $luval;
  }

  function interpValue($thistime, $ts, $tv, $nts, $ntv) {
    $this->intflag = 0;
    $this->intmethod = 0;
    if ($this->intflag == 2) {
       # places a limit on how long we can interpolate
       if ( abs($nts - $ts) > $this->ilimit ) {
          return NULL;
       }
    }
    switch ($this->intmethod) {
       case 0:
          // mean value
          $retval = $tv + ($ntv - $tv) * ( ($thistime - $ts) / ($nts - $ts) );
          //dsm("Interp: $retval = $tv + ($ntv - $tv) * ( ($thistime - $ts) / ($nts - $ts) )");
       break;

       case 1:
          // previous value
          $retval = $tv;
       break;

       case 2:
          // next value
          $retval = $ntv;
       break;

    }
    return $retval;
  }
  
  public function dh_getProp($entity, $propname = NULL, $view='') {
    // @todo: implement om routines
  }
  
  public function formatMatrix($force_refresh=0) {
    // @todo: implement om routines
  }
  public function evaluateMatrix($key1 = 'default', $key2 = 'factor') {
    // evaluateMatrix parameter defaults may vary by class implementing this
    // for this version 
  }
}


class dHWaterDemandProjectionCurrent extends dHWaterDemandProjectionBase {
  var $projected_mgy_varkey = 'wsp_wd_future_mgy';
  var $current_mgd_varkey = 'wsp_wd_current_mgd';
  
  public function formRowEdit(&$form, $entity) {
    $codename = $this->row_map['code'];
    $valname = $this->row_map['value'];
    $stimename = $this->row_map['start'];
    $etimename = $this->row_map['end'];
    $form[$stimename]['#weight'] = 1;
    $form[$etimename]['#weight'] = 2;
    $form[$valname]['#title'] = 'Current Annual Withdrawal (MGY)';
    $form[$valname]['#weight'] = 3;
    $form['proptext']['#weight'] = 4;
    
    // load the parent entity, get it's linked projections
    // get the parents org entity and it's linked projections
    // set these values as the options in the select list
        
    $form[$stimename]['#date_format'] = 'Y';
    $form[$stimename]['#title'] = 'Beginning Year';
    $form[$stimename]['#description'] = 'Starting year time period used to make current demand estimate.';
    $form[$etimename]['#date_format'] = 'Y';
    $form[$etimename]['#title'] = 'Ending Year';
    $form[$etimename]['#description'] = 'Ending year time period used to make current demand estimate.  If left blank, this will default to water supply plan start date';
    foreach ($this->hiddenFields() as $hide_this) {
      $form[$hide_this]['#type'] = 'hidden';
    }
  }
  
  public function formRowSave(&$rowvalues, &$row) {
    // special form save handlers
    $row->enddate = !empty($rowvalues['enddate']) ? $rowvalues['enddate'] . '-12-31' : '';
    $row->startdate = !empty($rowvalues['startdate']) ? $rowvalues['startdate'] . '-01-02' : '';
  }
  
  public function loadProjected($entity) {
    // only do this for a property, not a time series
    if ($entity->entityType() == 'dh_properties') {
      $cmgy_varid = array_shift(dh_varkey2varid($this->projected_mgy_varkey));
      $pmgy_info = array(
        'featureid' => $entity->featureid,
        'entity_type' => $entity->entity_type,
        'bundle' => 'dh_properties',
        'varid' => $cmgy_varid,
      );
      // *************************************************
      // Current MGY
      // *************************************************
      $pmgy_prec = dh_get_properties($pmgy_info, 'singular');
      if ($pmgy_prec) {
        $rec = array_shift($pmgy_prec['dh_properties']);
        $pmgy_prop = entity_load_single('dh_properties', $rec->pid);
      } else {
        $pmgy_prop = entity_create('dh_properties', $pmgy_info);
      }
      //dpm($pmgy_prop,'loaded pmgy_prop');
      return $pmgy_prop;
    }
    return FALSE;
  }
  public function save(&$entity) {
    // add a ts event to note a insert or edit
    $this->recordChange($entity);
  }
  
  public function update(&$entity) {
    // pass updates to all objects linked to this.
    // update occurs after save().
    // we do this on update, but not on insert, 
    // since if it is an insert there won't be anything linked to it yet
    $this->updateLinked($entity);
  }
  
  public function insert(&$entity) {
    // add a ts event to note a insert or edit
    //$this->recordChange($entity);
  }
  
  public function updateLinked(&$entity) {
    // @todo: put a stub for this in the base class
    // iterate through things linked to this and call a entity_load() and entity_save()
    $projected = $this->loadProjected($entity);
    if ($projected) {
      //dpm($projected, 'saving linked');
      entity_save($projected->entityType(), $projected);
    }
    // do the MGD version
    $mgd = $this->loadReplicant($entity, $this->current_mgd_varkey);
    //dpm($mgd,'current mgd');
    if ($mgd) {
      $mgd->propvalue = $entity->propvalue / 365.0;
      entity_save($mgd->entityType(), $mgd);
    }
  }
  
  public function recordChange(&$entity) {
    // add a ts event for this if this is a property
    // we must avoid doing this if it is a TS because we would create an endless recursion
    // @todo: move this to base class or module code
    // time resolutions:
    //   singular - only one ts event ever for this feature/varid combo
    //   tstime_singular - only onets event for this feature/varid/tstime combo
    $feature = $this->getParentEntity($entity);
    if ($entity->entityType() == 'dh_properties') {
      $ts_rec = array(
        'varid' => $entity->varid,
        'tsvalue' => $entity->propvalue,
        'tscode' => 'inserted',
        //'tstime' => mktime(),
        'tstime' => $entity->modified,
        'featureid' => $entity->featureid,
        'entity_type' => $feature->entityType(),
      );
      dh_update_timeseries($ts_rec, 'tstime_singular');
    }
  }
}

class dHWaterDemandProjectionValue extends dHWaterDemandProjectionBase {
  // the class that represents a projection value, 
  // Value Type:
  // * this value property may be linked to an instance of dHWaterDemandProjection
  //   or, it may be a standalone value.
  // ** standalone - projection and current are independent
  // ** linked - projection is calculated by loading the linked dHWaterDemandProjection and getting a factor, then multiplying that factor by the value of the current demand variable
  // Form Edit:
  // * regardless of projection Value Type this form should show the current mgy, proj mgy, current mgd, proj mgd, and select box for Value Type
  // * if Value Type is "linked" then it shows the select list for the linked projection
  
  var $current_mgy_varkey = 'wsp_current_use_mgy';
  var $projected_mgy_varkey = 'wsp_wd_future_mgy';
  var $current_mgd_varkey = 'wsp_wd_current_mgd';
  var $projected_mgd_varkey = 'wsp_wd_future_mgd';
  var $cat_var = 'wsp_mp_cat';
  var $save_method = 'form_entity_map';
  var $default_bundle = 'wsp_projection_value';
  
  public function __construct($conf = array()) {
    parent::__construct($conf);
    $hidden = array('pid', 'featureid', 'entity_type');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function loadCurrent($row) {
    $vars = dh_varkey2varid($this->current_mgy_varkey);
    $cmgy_varid = array_shift($vars);
    $cmgy_info = array(
      'featureid' => $row->featureid,
      'entity_type' => $row->entity_type,
      'bundle' => 'dh_properties',
      'varid' => $cmgy_varid,
    );
    // *************************************************
    // Current MGY
    // *************************************************
    //dpm($cmgy_info,' dh_get_timeseries cmgy_info');
    $cmgy_prec = dh_get_properties($cmgy_info, 'singular');
    if ($cmgy_prec) {
      
      $rec = array_shift($cmgy_prec['dh_properties']);
      $cmgy_prop = entity_load_single('dh_properties', $rec->pid);
    } else {
      //dpm($cmgy_info,'creating new current from dHWaterDemandProjectionValue');
      $cmgy_prop = entity_create('dh_properties', $cmgy_info);
    }
    return $cmgy_prop;
  }
  public function alterData(&$row) {
    // do the parent first which loads the incidence var
    // then use an EFQ to get the extent var
    if (!$row->entity_type) {
      return FALSE;
    } else {
      // load related properties
      $cmgy_prop = $this->loadCurrent($row);
      $row->cmgy_pid = $cmgy_prop->pid;
      $row->cmgy_varid = $cmgy_prop->varid;
      $row->cmgy_featureid = $cmgy_prop->featureid;
      $row->cmgy_entity_type = $cmgy_prop->entity_type;
      $row->cmgy_bundle = $cmgy_prop->bundle;
      $row->cmgy_code = $cmgy_prop->tscode;
      $row->cmgy_value = $cmgy_prop->propvalue;
    }
  }
  
  
  public function loadProjectionObject($row) {
    $eref = $row->field_linked_projection;
    $target = FALSE;
    $finfo = field_info_field('field_linked_projection');
    if (isset($eref['und']) and is_array($eref['und'])) {
      $first = $eref['und'][0];
      $target_id = $first['target_id'];
      $target = entity_load_single('dh_properties', $target_id);
    }
    return $target;
  }
  
  public function getProjectionFactor(&$entity) {
    // load the entity referenced projection object
    // load its plugin
    // set default to no growth in case the source returns FALSE indicating no projection is linked
    $cmgy_property = $this->loadCurrent($entity);
    $projection = $this->loadProjectionObject($entity);
    if (!$projection) {
      return 1.0;
    }
    $syear = date('Y', strtotime($projection->startdate));
    $eyear = date('Y', strtotime($projection->enddate));
    $cat = !empty($entity->propcode) ? $entity->propcode : $this->guessNewCat($entity);
    $config = array('category' => $cat);
    if (!empty($cmgy_property->enddate )) {
      $config['base_year'] = date('Y', dh_handletimestamp($cmgy_property->enddate));
    }
    //$config = array('category' => $entity->propcode, 'year' => $year); // @todo - we can manually specify the year here, but use the default from the projection
    // see: dh_getValue on source projection plugin above
    // check the $factor - if this is false, then we have a situation where the desired
    //   use category is not set in the linked projection, so we must choose a new default
    $factor = FALSE;
    //dpm($config,'conf');
    while ( !$factor and $cat) {
      $factor = $projection->dh_getValue(FALSE, 'factor', $config);
      if ($factor === FALSE) { 
        watchdog('dh_wsp', "Projection source (pid = $projection->pid) returned FALSE, assuming no growth (pid = $entity->pid) ");
        drupal_set_message("Cannot find selected projection category $cat");
        $cat = $this->guessNewCat($entity, $cat);
        if (!$cat) {
          // cannot find category, forcing factor to be 1
          break;
        }
        drupal_set_message("Trying alternative category $cat for pid = $entity->pid, Projection source (pid = $projection->pid)");
        $config['category'] = $cat;
      }
    }
    $factor = !$factor ? 1.0 : $factor;
    $entity->propcode = $cat;
    //dpm($entity,'updating entity');
    //dpm($factor,' factors');
    return $factor;
  }
  
  function guessNewCat($entity, $lastcat = '') {
    // iterates through options for category, if it can find none, returns FALSE
    // get the parent entity
    if ($lastcat == 'Base Rate') {
      // we're already at the bottom
      return FALSE;
    } else {
      $feature = $this->getParentEntity($entity);
      $options = array(
        'wsp_plan_system-ssuag' => 'Agriculture',
        'wsp_plan_system-ssulg' => 'Large SSU',
        'wsp_plan_system-cws' => 'Residential',
        'wsp_plan_system-ssusm' => 'Small SSU on GW',
      );
      $guess = (isset($options[$feature->ftype]) and ($lastcat <> $options[$feature->ftype])) ? $options[$feature->ftype] : 'Base Rate';
      //dpm($options[$feature->ftype],"Feature: $entity->featureid - options[feature->ftype]");
      //dpm($options,"$guess = $feature->ftype and ($lastcat <> $feature->ftype) ? ");
      return $guess;
    }
    
    // @todo: Implement fancy handling here with getCatTable()
    
    // get options based on its ftype & if LgSSU it's sub-category
    // load category prop
    $criteria = array(); 
    $criteria[] = array(
      'name' => 'varid',
      'op' => 'IN',
      'value' => dh_varkey2varid($this->cat_var),
    );
    $feature->loadComponents($criteria);
    $cat_prop = $feature->dh_props[$feature->prop_varkey_map[$this->cat_var]];
    $cat_mp = is_object($cat_prop) ? $cat_prop->propcode : '';
    // return the next cat found, if cat is '' then this is the first time, so just get the first match
    $options = $this->getCatTable();
    if (!isset($options[$parent->ftype])) {
      return FALSE;
    }
    foreach ($options[$parent->ftype] as $match_cat_mp => $options) {
      if ( ($cat_mp == $match_cat_mp) or ($cat_mp == '' and $match_cat_mp == 'all')) {
        
      }
    }
  }
  
  public function formRowSubmit(&$rowform, $row) {
    // @todo: fail if factor is false? 
    //dpm($row->field_linked_projection,'->field_linked_projection');
    // maybe not because what if all factors are false?  Return 1.0 and move on?
    switch ($row->propcode) {
      case 'custom':
      case 'Custom':
      unset($row->field_linked_projection);
      break;
      
      default:
      $factor = $this->getProjectionFactor($row);
      break;
    }
    
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $row->bundle = !empty($row->bundle) ? $row->bundle : 'wsp_projection_value';
    $varinfo = $row->varid ? dh_vardef_info($row->varid) : FALSE;
    if (!$varinfo) {
      return FALSE;
    }
    $element_name = $this->projected_mgy_varkey . '-options' . '-' . $row->featureid;
    $codename = $this->row_map['code'];
    $valname = $this->row_map['value'];
    $stimename = $this->row_map['start'];
    $etimename = $this->row_map['end'];
    // now load the related variable info
    $this->alterData($row);
    $rowform['cmgy_pid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->cmgy_pid,
    );
    $rowform['cmgy_varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->cmgy_varid,
    );
    $rowform['cmgy_entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->cmgy_entity_type,
    );
    $mgy_digits = ($row->cmgy_value >= 0.1) ? 2 : 4;
    $mgd_digits = (($row->cmgy_value / 365.0) >= 0.1) ? 2 : 4;
    $rowform['cmgy_value'] = array(
      '#title' => t('Current Annual Demand'),
      '#type' => 'item',
      '#markup' => round($row->cmgy_value,$mgy_digits) . ' MGY / ' . round($row->cmgy_value / 365.0,$mgd_digits) . ' MGD',
      '#weight' => 2,
      '#required' => FALSE,
    );
    $bundle_opts = array(
      'dh_properties' => 'Custom',
      'wsp_projection_value' => 'Linked',
    );
    $fs = array();
    field_attach_form('dh_properties', $row, $rowform, $fs);
    $rowform[$valname]['#prefix'] = "<div id='$element_name'>" . $rowform[$valname]['#prefix'];
    $rowform['field_linked_projection']['#weight'] = 35;
    $rowform['field_linked_projection']['#suffix'] = $rowform['field_linked_projection']['#suffix'] . "</div>";
    $option_ids = $this->getOrgProjectionList($row);
    if (is_array($rowform['field_linked_projection']['und']['#default_value'])) {
      $option_ids = array_merge($option_ids, $rowform['field_linked_projection']['und']['#default_value']);
      $option_ids = array_unique($option_ids);
    }
    foreach ($rowform['field_linked_projection']['und']['#options'] as $opid => $opt) {
      if (!in_array($opid, $option_ids)) {
        unset($rowform['field_linked_projection']['und']['#options'][$opid]);
      }
    }
    $proj_cat = $this->getProjCatList();
    // look at linked projection used 
    switch ($row->propcode) {
      case 'custom':
      case 'Custom':
      break;
      
      default:
      // load the linked projection entity and get the factor
      // this function also guesses the category if none given
      $factor = $this->getProjectionFactor($row);
    }
    $rowform[$codename]['#title'] = 'Use Category';
    $rowform[$codename]['#description'] = 'Type of use that best describes this system - if unknown use Base Rate.';
    $rowform[$codename]['#type'] = 'select';
    // @todo - filter this list by those non-null in linked projection (if not custom)
    //   throw a message to the user if the selected value is not set
    $rowform[$codename]['#options'] = $proj_cat;
    $rowform[$codename]['#default_value'] = !empty($row->$codename) ? $row->$codename : 'Base Rate';
    $rowform[$codename]['#size'] = 1;
    $rowform[$codename]['#weight'] = 1;
    // @todo: update projected estimate when category changes
    /*
    $rowform[$codename]['#ajax'] = array(
      'callback' => 'dh_rebuild_plugin',
      'wrapper' => $element_name,
    );
    */
    
    // Set visibility/editability of value and linked projection if this is custom or not
    $lstates = array(
      'disabled' => array(
        ':input[name="propcode"]' => array('value' => "custom"),
        ':input[name="propcode"]' => array('value' => "Custom"),
      ),
    );
    $rowform['field_linked_projection']['und']['#states'] = $lstates;
    $cstates = array(
      'enabled' => array(
        ':input[name="propcode"]' => array('value' => "custom"),
        ':input[name="propcode"]' => array('value' => "Custom"),
      ),
    );
    $rowform[$valname]['#states'] = $cstates;
    
    switch ($row->propcode) {
      case 'custom':
      case 'Custom':
      // should do nothing since this is a normal edit form 
      // but hide the entity ref if it exists
      unset($rowform['field_linked_projection']);
      $rowform[$valname]['#title'] = t('Future Demand');
      $rowform[$valname]['#type'] = 'textfield';
      $rowform[$valname]['#description'] = 'Custom Rate selected.  Enter custom value for projected water use here.  ';
      break;
      
      default:
      $mgy_digits = (($factor * $row->cmgy_value) >= 0.1) ? 2 : 4;
      $mgd_digits = (($factor * $row->cmgy_value / 365.0) >= 0.1) ? 2 : 4;
      $rowform[$valname]['#type'] = 'textfield';
      $rowform[$valname]['#markup'] = round($factor * $row->cmgy_value,$mgy_digits) . ' MGY / ' . round($factor * $row->cmgy_value / 365.0,$mgd_digits) . ' MGD';
      $rowform[$valname]['#default_value'] = $factor * $row->cmgy_value;
      break;
    }
    $rowform[$valname]['#weight'] = 3;
    
    $hidden = array('pid', 'end_date', 'featureid', 'entity_type');
    $rowform['actions']['submit']['#value'] = t('Save Projection');
    $rowform['actions']['delete']['#value'] = t('Delete Projection');

    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    return;
  }
  
  public function getOrgProjectionList($entity) {
    // find submittal
    $parent = $this->getParentEntity($entity);
    //dpm($parent,'parent of projection property');
    $tree = array();
    // the base entity here should be a system submittal.
    // get projections attached to this submittals locality registration or to locality region.
    $links = array('dh_link_admin_reg_holder', 'dh_link_admin_submittal_pr');
    $tree_status = dh_get_eref_tree($links, $parent, $tree);
    //dpm($tree_status,'tree_status');
    //dpm($tree,'tree');
    // Now, if desired we can 
    // get projections attached to other localities in the region.
    foreach ($tree as $type => $entities) {
      foreach ($entities as $entity_id) {
        $eref_config = array(  
          'eref_fieldname' => 'dh_link_admin_reg_holder',
          'target_entity_id' => $entity_id, 
          'entity_type' => 'dh_adminreg_feature', 
          'entity_id_name' => 'adminid'
        );
        $other_localities = dh_get_reverse_erefs($eref_config);
        $merged = array_merge($tree['dh_adminreg_feature'], $other_localities);
        $tree['dh_adminreg_feature'] = array_unique($merged);
      }
    }
    //dpm($tree, 'final tree');
    // only consider adminreg features for now
    $tree = $tree['dh_adminreg_feature'];
    $q = db_query("select pid from {dh_properties} where bundle = 'wsp_projection' and entity_type = 'dh_adminreg_feature' and featureid in (:fids)", array(':fids' => $tree));
    $options = $q->fetchCol();
    //dpm($options,'result of fetch');
    return $options;
    // find find plan 
    // find organization
    // find all org plans
    // find all projection linked to org plans 
  }
  
  public function getProjCatList() {
    // find submittal
    // find find plan 
    // find organization
    // find all org plans
    // find all projection linked to org plans
    $proj_cat = array(
      'Base Rate' => 'Base Rate' ,
      'Agriculture' => 'Agriculture',
      'Com/Inst/LI' => 'Com/Inst/LI' ,
      'Heavy Industry' => 'Heavy Industry' ,
      'Large SSU' => 'Large SSU',
      'Military' => 'Military',
      'Other' => 'Other',
      'Process Loss' => 'Process Loss',
      'Residential' => 'Residential' ,
      'Sales' => 'Sales',
      'Small SSU on GW' => 'Small SSU on GW',
      'Unaccounted Loss' => 'Unaccounted Loss',
      'Custom' => 'Custom Rate' ,
    );
    return $proj_cat;    
  }

  public function save(&$entity) {
    // the dust has settled, now scale according to the parent current value if linked, or just use manual
    // and then update the mgd doppleganger
    switch ($entity->propcode) {
      case 'Custom':
      case 'custom':
      $entity->field_linked_projection['und'] = array();
      break;
      
      default:
      // load current mgy entity
      // load the linked projection table
      // get the scaling factor for the category
      $cmgy_prop = $this->loadCurrent($entity);
      $factor = $this->getProjectionFactor($entity);
      $entity->propvalue = $factor * $cmgy_prop->propvalue;
      break;
    }
  }
  
  public function update(&$entity) {
    // pass updates to all objects linked to this.
    // update occurs after save().
    // we do this on update, but not on insert, 
    // since if it is an insert there won't be anything linked to it yet
    $this->updateLinked($entity);
  }
  
  public function updateLinked(&$entity) {
    // @todo: put a stub for this in the base class
    // do the MGD version
    $mgd = $this->loadReplicant($entity, $this->projected_mgd_varkey);
    if ($mgd) {
      $mgd->propvalue = $entity->propvalue / 365.0;
      entity_save($mgd->entityType(), $mgd);
    }
  }
  
  public function buildContent(&$content, &$entity, $view_mode) {
    // @todo: handle teaser mode and full mode with plugin support
    //        this won't happen till we enable at module level however, now it only 
    //        is shown when selecting "plugin" in the view mode in views
    //dsm($view_mode);
    $proj_cat = $entity->propcode;
    $cmgy_prop = $this->loadCurrent($entity);
    $current_value = round($cmgy_prop->propvalue,2);
    $proj_value = round($entity->propvalue,2);
    $pct = ($current_value > 0) ? round(100.0*(($entity->propvalue - $cmgy_prop->propvalue)/$cmgy_prop->propvalue),1) . '%' : 'n/a';
    $sign = ($pct > 0) ? '+' : '';
    $proj_units = 'mgy';
    switch ($view_mode) {
      case 'teaser':
      case 'plugin':
        $content = array();
        $content['value'] = array(
          '#type' => 'item',
          '#markup' => "From $current_value to $proj_value $proj_units ($sign$pct)",
        );
      break;
      default:
      // just accept the parent version
      break;
    }
  }
  
}
?>
