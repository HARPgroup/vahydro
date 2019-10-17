<?php
module_load_include('inc', 'dh', 'plugins/dh.display');
module_load_include('inc', 'tablefield');


/**
 * Helper function to translate tablefield to associative array.
 * @todo: move this to tablefield after it is ready to roll
 */


class dHLandUseBase extends dHVariablePluginDefault {
  // loads land use table from tablefield
  // gets years/dates from header row 0
  // iterates through all rows adding land use value at points in time 
  // optional to let user specify that they want to do interpolated annual values?
  // tscode = luname
  var $luval_varkey = 'landuse_acres';
  var $luval_matrix_field = 'field_dh_matrix';
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    foreach ($this->hiddenFields as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function hiddenFields() {
    return array('pid', 'startdate', 'enddate', 'varid', 'featureid', 'entity_type', 'bundle','dh_link_admin_pr_condition');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // special render handlers when displaying in a grouped property block
    $row->propvalue = number_format($row->propvalue, 3);
  }
  
  public function formRowEdit(&$rowform, $entity) {
    // special render handlers when displaying in a grouped property block
    //dpm($entity,'entity');
    $rowform['propname']['#title'] = 'Dataset Name';
    $rowform['propvalue']['#title'] = 'Force Total Land Use Area (' . $entity->varunits . ')';
    $rowform['propvalue']['#description'] = "FUNCTION NOT YET ENABLED. Enter a value here to insure consistent area regardless of tabular data input inconsistencies.  Remaining landuse will be made up from 'default land use' setting below.  If land area exceeds 'Total Land Use' all land uses will be shrunk proportionally to match total.  If this field is null, no land use area correction will be made.";
    $this->hideFormRowEditFields($rowform);
    $rowform['propcode']['#title'] = 'Default Land Use for Scaling';
    $rowform['propcode']['#description'] = 'FUNCTION NOT YET ENABLED. Default landuse category to use to make up missing land area if scaling to a fixed area is requested.';
    $rowform['propcode']['#type'] = 'select';
    $rowform['propcode']['#size'] = 1;
    $lus = $this->getTableLandUses($entity);
    $rowform['propcode']['#options'] = array_combine($lus, $lus);
  }
  
  public function getTableLandUses($entity) {
    $tablefield = $entity->{$this->luval_matrix_field}['und'][0];
    // this is weird, under Field loading it becomes ['tabledata']['tabledata']?
    //    Is this a bug I am introducing or is it just how it meshes with form API?
    $tabledata = isset($tablefield['tablefield']) ? $tablefield['tablefield']['tabledata'] : $tablefield['tabledata']['tabledata'];
    $lutable = tablefield_to_associative($tabledata);
    $landuses = array_keys($lutable);
    return $landuses;
  }
  
  public function setUp(&$entity) {
  }
  
  public function load(&$entity) {
    // get field default basics
    if ($entity->is_new or $entity->reset_defaults) {
      $lutable = $this->tableDefault();
      // uses tablefield_parse_assoc() to translate from OM format to tablefield non-associative
      //   which is essentially a flattening routine
      list($lutable, $row_count, $max_col_count) = tablefield_parse_assoc($lutable);
      $this->setLUTableField($entity, $lutable);
    }
    //error_log("load() called on $entity->propname");
    $entity->test_attribute = 'this is a test.';
    //error_log("$entity->propname" . print_r((array)$entity,1));
  }
  
  public function tableDefault() {
    // Returns associative array keyed table (like is used in OM)
    // This format is not used by Drupal however, so a translation 
    //   with tablefield_parse_assoc() is usually in order (such as is done in load)
    // set up defaults - we can sub-class this to handle each version of the model land use
    // This version is based on the Chesapeake Bay Watershed Phase 5.3.2 model land uses
    // this brings in an associative array keyed as $table[$luname] = array( $year => $area )
    $table = array();
    $years = range(1980,2020,5);
    array_unshift($years, 'luname');
    $lus = array('afo', 'ccn', 'cfo', 'for', 'hvf', 'hyo', 'lwm', 'nex', 'nho', 'nid', 'npa', 'pas', 'rex', 'trp', 'alf', 'cex', 'cid', 'cpd', 'hom', 'hwm', 'hyw', 'nal', 'nhi', 'nhy', 'nlo', 'npd', 'rcn', 'rid', 'rpd', 'urs', 'wat');
    sort($lus);
    foreach ($lus as $thislu) {
      $yearkeys = $years;
      $table[$thislu] = array_fill_keys(array_values($yearkeys), 0.0);
      $table[$thislu]['luname'] = $thislu; // replace the 0.0 with the luname
    }
    // put the header line on top
    array_unshift($table, $years);
    return $table;
  }
  
  public function create(&$entity) {
    // set up defaults?
  }
  
  public function save(&$entity) {
    // pass updates to all objects linked to this.
    //dpm($entity->field_dh_matrix, 'tablefield on save()');
    $this->updateLinkedLUTS($entity);
  }
  
  function setLUTableField(&$entity, $csvtable) {
    // requires a table to be set in non-associative format (essentially a csv)
    $instance = field_info_instance($entity->entityType(), $this->luval_matrix_field, $entity->bundle);
    $field = field_info_field($this->luval_matrix_field);
    $default = field_get_default_value($entity->entityType(), $entity, $field, $instance);
    //dpm($default,'default');
    list($imported_tablefield, $row_count, $max_col_count) = dh_tablefield_parse_array($csvtable);
    // set some default basics
    $default[0]['tablefield']['tabledata'] = $imported_tablefield;
    $default[0]['tablefield']['rebuild']['count_cols'] = $max_col_count;
    $default[0]['tablefield']['rebuild']['count_rows'] = $row_count;
    if (function_exists('tablefield_serialize')) {
      $default[0]['value'] = tablefield_serialize($field, $default[0]['tablefield']);
    } else {
      $default[0]['value'] = serialize($default[0]['tablefield']);
    }
    $default[0]['format'] = !isset($default[0]['format']) ? NULL : $default[0]['format'];
    $entity->{$this->luval_matrix_field} = array(
      'und' => $default
    );
  }
  
  public function updateLinkedLUTS(&$entity) {
    // @todo: allow sophisticated date interpolations for populating the timeseries table.
    //        for now this just puts in single values per time column interpolated by year
    // iterate through land use values in the table
    // @todo: delete all timeseries records that no longer are within the set to allow 
    //        full management of dates and land use categories without accumulating garbage
    // converts to OM format, which makes it easy to track landuse, eliminate the header row, and allows interpolation if we so desire
    //dpm($entity,'entity');
    $lutable = tablefield_to_associative($entity->{$this->luval_matrix_field}['und'][0]['tablefield']['tabledata']); 
    $interpall = FALSE; // @todo: allow this to be set somewhere, or assumed if date fields are a year
                        //        this can become very data intesive if the years are wide spread
    $keepers = array();
    //dpm($entity, 'entity');
    //dpm($lutable, 'tablefield_to_associative');
    $vars = dh_varkey2varid($this->luval_varkey);
    $varid = array_shift($vars);
    $ts_info = array(
      'featureid' => $entity->pid,
      'entity_type' => 'dh_properties',
      'bundle' => 'dh_timeseries',
      'varid' => $varid,
    );
    foreach ($lutable as $luname => $luts) {
      ksort($luts);
      if ($interpall) {
        for ($i = min(array_keys($luts)); $i<= max(array_keys($luts)); $i++) {
          $newluts[$i] = $this->doLookup($luts, $i, 0);
        }
        $luts = $newluts;
      }
      //dpm($newluts,'newluts');
      //dpm($luts,'luts');
      foreach ($luts as $ts => $tsval) {
        if (empty($ts)) {
          continue;
        }
        list($tsyear) = explode('-', $ts);
        $ts = ($tsyear == $ts) ? "$tsyear-01-01" : $ts; 
        $vars = dh_varkey2varid($this->luval_varkey);
        $ts_info['tscode'] = $luname;
        $ts_info['tstime'] = $ts;
        $ts = dh_get_timeseries($ts_info, 'tstimecode_singular');
        if ($ts) {
          $tsptr = array_shift($ts['dh_timeseries']);
          $tsrec = entity_load_single('dh_timeseries', $tsptr->tid);
        } else {
          $tsrec = entity_create('dh_timeseries', $ts_info);
        }
        $tsrec->tsvalue = $tsval;
        $tsrec->save();
        if ($tsrec->tid) {
          // this keeps a record of all intentionally added, even interpolated records if we chose that
          $keepers[$tsrec->tid] = $tsrec->tid;
        }
      }
    }
    // now, find all the stragglers that no longer fit
    unset($ts_info['tscode']);
    unset($ts_info['tstime']);
    $discard = array();
    $ts = dh_get_timeseries($ts_info, 'all');
    if (isset($ts['dh_timeseries'])) {
      foreach ($ts['dh_timeseries'] as $thists) {
        if (property_exists($thists, 'tid') and !isset($keepers[$thists->tid])) {
          $discard[] = $thists->tid;
        }
      }
    }
    if (count($discard)) {
      entity_delete_multiple('dh_timeseries', $discard);
    }
  }
  
  function doLookup($values, $key, $default_value){
  
    $lukeys = array_keys($values);
    $luval = $default_value;
    for ($i=0; $i < (count($lukeys) - 1); $i++) {
       $lokey = $lukeys[$i];
       $hikey = $lukeys[$i+1];
       $loval = $values[$lokey];
       $hival = $values[$hikey];
       $minkey = min(array($lokey,$hikey));
       $maxkey = max(array($lokey,$hikey));
       if ( ($minkey <= $key) and ($maxkey >= $key) ) {
          $luval = $this->interpValue($key, $lokey, $loval, $hikey, $hival);
       }
    }
    //dpm($luval,$key . ': final value');
    return $luval;
  }

  function interpValue($thistime, $ts, $tv, $nts, $ntv, $method = 0) {
    switch ($method) {
       case 0:
          // mean value
          $retval = $tv + ($ntv - $tv) * ( ($thistime - $ts) / ($nts - $ts) );
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
}



class dHHSPFPerlnd extends dHVariablePluginDefault {
  // loads land use table from tablefield
  // gets years/dates from header row 0
  // iterates through all rows adding land use value at points in time 
  // optional to let user specify that they want to do interpolated annual values?
  // tscode = luname
  var $luval_varkey = 'area_acres';
  var $cover_varkey = 'hspf_crop_cover';
  var $luval_matrix_field = 'field_dh_matrix';
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    foreach ($this->hiddenFields as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function hiddenFields() {
    return array('pid', 'startdate', 'enddate', 'varid', 'featureid', 'entity_type', 'bundle','dh_link_admin_pr_condition');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // special render handlers when displaying in a grouped property block
    $row->propvalue = number_format($row->propvalue, 3);
  }
  
  public function formRowEdit(&$rowform, $entity) {
    // special render handlers when displaying in a grouped property block
    //dpm($entity,'entity');
    $rowform['propname']['#title'] = 'Dataset Name';
    $rowform['propvalue']['#title'] = 'Force Total Land Use Area (' . $entity->varunits . ')';
    $rowform['propvalue']['#description'] = "FUNCTION NOT YET ENABLED. Enter a value here to insure consistent area regardless of tabular data input inconsistencies.  Remaining landuse will be made up from 'default land use' setting below.  If land area exceeds 'Total Land Use' all land uses will be shrunk proportionally to match total.  If this field is null, no land use area correction will be made.";
    $this->hideFormRowEditFields($rowform);
    $rowform['propcode']['#title'] = 'Default Land Use for Scaling';
    $rowform['propcode']['#description'] = 'FUNCTION NOT YET ENABLED. Default landuse category to use to make up missing land area if scaling to a fixed area is requested.';
    $rowform['propcode']['#type'] = 'select';
    $rowform['propcode']['#size'] = 1;
    $lus = $this->getTableLandUses($entity);
    $rowform['propcode']['#options'] = array_combine($lus, $lus);
  }
  
  public function setUp(&$entity) {
  }
  
  public function load(&$entity) {
    // get field default basics
    if ($entity->is_new or $entity->reset_defaults) {
      $lutable = $this->tableDefault();
      // uses tablefield_parse_assoc() to translate from OM format to tablefield non-associative
      //   which is essentially a flattening routine
      list($lutable, $row_count, $max_col_count) = tablefield_parse_assoc($lutable);
      $this->setLUTableField($entity, $lutable);
    }
    //error_log("load() called on $entity->propname");
    $entity->test_attribute = 'this is a test.';
    //error_log("$entity->propname" . print_r((array)$entity,1));
  }
  
  public function create(&$entity) {
    // set up defaults?
  }
  
  public function save(&$entity) {
    // pass updates to all objects linked to this.
    //dpm($entity->field_dh_matrix, 'tablefield on save()');
    $this->updateLinkedLUTS($entity);
  }
}



class dHLandCoverBase extends dHVariablePluginDefault {
  // @todo:
  // __construct() - call parent getScenarioFile() set $this->land_cover_file
  // insert() - open land cover file, look for matching values if they exist and tablefield is emty, use, 
  //            otherwise grab defaults from tableDefault()
  // save() - take values in table, insert or overwrite lines in CSV file
  // updateLinkedLCTS() - create ts values for each lu and month combo -- use year from prop startdate
  var $luval_varkey = 'landuse_acres';
  var $luval_matrix_field = 'field_dh_matrix';
  var $land_cover_file = '/opt/model/p53/p532c-sova/input/scenario/land/crop_cover/crop_cover_1985CALIBN040611.csv';
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    foreach ($this->hiddenFields as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function hiddenFields() {
    return array('pid', 'startdate', 'enddate', 'varid', 'featureid', 'entity_type', 'bundle','dh_link_admin_pr_condition');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // special render handlers when displaying in a grouped property block
    $row->propvalue = number_format($row->propvalue, 3);
  }
  
  public function formRowEdit(&$rowform, $entity) {
    // special render handlers when displaying in a grouped property block
    //dpm($entity,'entity');
    $rowform['propname']['#title'] = 'Land Cover';
    $rowform['propvalue']['#title'] = 'Default Cover Value';
    $rowform['propvalue']['#description'] = "FUNCTION NOT YET ENABLED. Enter a value here to insure consistent area regardless of tabular data input inconsistencies. ";
    $this->hideFormRowEditFields($rowform);
  }
  
  public function getTableLandCover($entity) {
    $tablefield = $entity->{$this->luval_matrix_field}['und'][0];
    // this is weird, under Field loading it becomes ['tabledata']['tabledata']?
    //    Is this a bug I am introducing or is it just how it meshes with form API?
    $tabledata = isset($tablefield['tablefield']) ? $tablefield['tablefield']['tabledata'] : $tablefield['tabledata']['tabledata'];
    $lutable = tablefield_to_associative($tabledata);
    $landuses = array_keys($lutable);
    return $landuses;
  }
  
  public function setUp(&$entity) {
  }
  
  public function load(&$entity) {
    // get field default basics
    if ($entity->is_new or $entity->reset_defaults) {
      $lutable = $this->tableDefault();
      // uses tablefield_parse_assoc() to translate from OM format to tablefield non-associative
      //   which is essentially a flattening routine
      list($lutable, $row_count, $max_col_count) = tablefield_parse_assoc($lutable);
      $this->setLCTableField($entity, $lutable);
    }
    //error_log("load() called on $entity->propname");
    $entity->test_attribute = 'this is a test.';
    //error_log("$entity->propname" . print_r((array)$entity,1));
  }
  
  public function tableDefault() {
    // Returns associative array keyed table (like is used in OM)
    // This format is not used by Drupal however, so a translation 
    //   with tablefield_parse_assoc() is usually in order (such as is done in load)
    // set up defaults - we can sub-class this to handle each version of the model land use
    // This version is based on the Chesapeake Bay Watershed Phase 5.3.2 model land uses
    // this brings in an associative array keyed as $table[$luname] = array( $year => $area )
    $table = array();
    $def_lus = array('nhy', 'nal', 'hyw', 'lwm', 'npa', 'nlo', 'alf', 'pas', 'nho', 'urs', 'nhi', 'cpd', 'trp', 'hwm', 'hom', 'rpd', 'npd', 'hyo');
    // load the SEDMNT.csv from each land use to obtain defaults in case there is no time-varying
    // this file is in the path: ./input/param/[luabbrev]/[scenario]/SEDMNT.csv
    //    ex: /opt/model/p53/p532c-sova/input/param/hwm/p532cal/SEDMNT.csv
    // there is 1 entry for each land segment in this file (or should be anyhow)
    // if there are NEITHER time varying nor defaults, use static land use defaults below

    $def_csv = array();
    // def_csv - we need to specify land use specific defaults if they are missing from static files
    $def_csv[] = "A51019,pas,0.53496575,0.56105387,0.75139433,0.84394467,0.79545701,0.89053345,0.74008203,0.82691425,0.68397498,0.7415607,0.64190769,0.61957157";
    $def_csv .= "A51019,trp,0.47076982,0.49372739,0.66122705,0.74267125,0.70000207,0.78366941,0.65127212,0.72768456,0.60189801,0.65257335,0.5648787,0.54522294";
    $def_csv[] = "A51019,hwm,0.32708129,0.3269254,0.31858158,8.1151269E-2,0.17664564,0.62777776,0.83781242,0.69648987,0.42473525,0.37571901,0.3456496,0.30400914";
    $def_csv[] = "A51019,hom,0.47526136,0.47369957,0.35832557,0.37377152,0.48488182,0.61517298,0.74684769,0.75078577,0.71671426,0.68986893,0.64025331,0.53385746";
    $def_csv[] = "A51019,npd,0.44999996,0.49535719,0.78935492,0.91333342,0.82903218,0.94999999,0.84354842,0.94999999,0.74599999,0.77225798,0.59899998,0.5970968";
    $def_csv[] = "A51019,urs,0.45214346,0.44324729,0.33691502,0.18682456,0.20292829,0.41975793,0.72384787,0.74974018,0.62691903,0.50858504,0.47929445,0.46204931";
    $def_csv[] = "A51019,hyo,0.43887249,0.48002377,0.73913169,0.83582741,0.75832778,0.93520314,0.84055716,0.94999999,0.71564668,0.73226488,0.57424134,0.57232916";
    $def_csv[] = "A51019,hyw,0.44397283,0.48626369,0.7541917,0.86363882,0.78651017,0.94999999,0.83916634,0.94999999,0.73854321,0.75982136,0.58950627,0.57036352";
    $def_csv[] = "A51019,lwm,0.4027718,0.39739239,0.38809657,0.38619283,0.36232397,0.3984234,0.73765594,0.73504877,0.49593991,0.43799391,0.41659057,0.4059197";
    $def_csv[] = "A51019,alf,0.21580648,0.20357139,0.1809677,0.26466671,0.4054839,0.66799998,0.56258059,0.5929032,0.66900003,0.2932258,0.2676667,0.2445161";
    $def_csv[] = "A51019,rpd,0.44999999,0.49535719,0.78935492,0.91333342,0.82903218,0.94999999,0.84354842,0.94999999,0.74599999,0.77225798,0.59899998,0.5970968";
    $header = explode(",", "landseg,landuse,jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec");
    foreach ($def_csv as $thislu) {
      $vals = explode(',', $thislu);
      $luname = $vals[1];
      $table[$luname] = array_fill_keys(array_values($header), $thislu);
    }

    // put the header line on top
    array_unshift($table, $years);
    return $table;
  }
  
  public function create(&$entity) {
    // set up defaults?
  }
  
  public function save(&$entity) {
    // pass updates to all objects linked to this.
    //dpm($entity->field_dh_matrix, 'tablefield on save()');
    $this->updateLinkedLCTS($entity);
  }
  
  function setLCTableField(&$entity, $csvtable) {
    // requires a table to be set in non-associative format (essentially a csv)
    $instance = field_info_instance($entity->entityType(), $this->luval_matrix_field, $entity->bundle);
    $field = field_info_field($this->luval_matrix_field);
    $default = field_get_default_value($entity->entityType(), $entity, $field, $instance);
    dpm($default,'default');
    list($imported_tablefield, $row_count, $max_col_count) = dh_tablefield_parse_array($csvtable);
    // set some default basics
    $default[0]['tablefield']['tabledata'] = $imported_tablefield;
    $default[0]['tablefield']['rebuild']['count_cols'] = $max_col_count;
    $default[0]['tablefield']['rebuild']['count_rows'] = $row_count;
    if (function_exists('tablefield_serialize')) {
      $default[0]['value'] = tablefield_serialize($field, $default[0]['tablefield']);
    } else {
      $default[0]['value'] = serialize($default[0]['tablefield']);
    }
    $default[0]['format'] = !isset($default[0]['format']) ? NULL : $default[0]['format'];
    $entity->{$this->luval_matrix_field} = array(
      'und' => $default
    );
  }
  
  public function updateLinkedLCTS(&$entity) {
    // @todo: allow sophisticated date interpolations for populating the timeseries table.
    //        for now this just puts in single values per time column interpolated by year
    // iterate through land use values in the table
    // @todo: delete all timeseries records that no longer are within the set to allow 
    //        full management of dates and land use categories without accumulating garbage
    // converts to OM format, which makes it easy to track landuse, eliminate the header row, and allows interpolation if we so desire
    //dpm($entity,'entity');
    $lutable = tablefield_to_associative($entity->{$this->luval_matrix_field}['und'][0]['tablefield']['tabledata']); 
    $interpall = FALSE; // @todo: allow this to be set somewhere, or assumed if date fields are a year
                        //        this can become very data intesive if the years are wide spread
    $keepers = array();
    //dpm($entity, 'entity');
    //dpm($lutable, 'tablefield_to_associative');
    $vars = dh_varkey2varid($this->luval_varkey);
    $varid = array_shift($vars);
    $ts_info = array(
      'featureid' => $entity->pid,
      'entity_type' => 'dh_properties',
      'bundle' => 'dh_timeseries',
      'varid' => $varid,
    );
    foreach ($lutable as $luname => $luts) {
      ksort($luts);
      if ($interpall) {
        for ($i = min(array_keys($luts)); $i<= max(array_keys($luts)); $i++) {
          $newluts[$i] = $this->doLookup($luts, $i, 0);
        }
        $luts = $newluts;
      }
      //dpm($newluts,'newluts');
      //dpm($luts,'luts');
      foreach ($luts as $ts => $tsval) {
        if (empty($ts)) {
          continue;
        }
        list($tsyear) = explode('-', $ts);
        $ts = ($tsyear == $ts) ? "$tsyear-01-01" : $ts; 
        $vars = dh_varkey2varid($this->luval_varkey);
        $ts_info['tscode'] = $luname;
        $ts_info['tstime'] = $ts;
        $ts = dh_get_timeseries($ts_info, 'tstimecode_singular');
        if ($ts) {
          $tsptr = array_shift($ts['dh_timeseries']);
          $tsrec = entity_load_single('dh_timeseries', $tsptr->tid);
        } else {
          $tsrec = entity_create('dh_timeseries', $ts_info);
        }
        $tsrec->tsvalue = $tsval;
        $tsrec->save();
        if ($tsrec->tid) {
          // this keeps a record of all intentionally added, even interpolated records if we chose that
          $keepers[$tsrec->tid] = $tsrec->tid;
        }
      }
    }
    // now, find all the stragglers that no longer fit
    unset($ts_info['tscode']);
    unset($ts_info['tstime']);
    $discard = array();
    $ts = dh_get_timeseries($ts_info, 'all');
    if (isset($ts['dh_timeseries'])) {
      foreach ($ts['dh_timeseries'] as $thists) {
        if (property_exists($thists, 'tid') and !isset($keepers[$thists->tid])) {
          $discard[] = $thists->tid;
        }
      }
    }
    if (count($discard)) {
      entity_delete_multiple('dh_timeseries', $discard);
    }
  }
}
?>