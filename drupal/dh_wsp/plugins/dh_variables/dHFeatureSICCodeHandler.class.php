<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHFeatureSICCodeHandler extends dHVariablePluginDefault {
  var $feature_sic_prop = 'ftype';
  // @todo:
  // this widget gets the ftype of the feature corresponding to featureid and entity_type
  // then it provides list of SIC options that correspond to that ftype
  // it provides ftype select list which when changed will update options with ajax
  
  public function __construct($conf = array()) {
    parent::__construct($conf);
  }
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    // set up config form default options
    $this->property_conf_default = array(
      'varname' => array('name'=>'varname','hidden' => 0),
      'propcode' => array('name'=>'propcode','hidden' => 0),
      'propvalue' => array('name'=>'propvalue','hidden' => 0),
      'pid' => array('name'=>'pid','hidden' => 1),
      'entity_type' => array('name'=>'entity_type','hidden' => 1),
      'featureid' => array('name'=>'featureid','hidden' => 1),
      'propname' => array('name'=>'propname','hidden' => 1),
      'status' => array('name'=>'status','hidden' => 1, 'no_config' => TRUE),
      'varid' => array('name'=>'varid', 'hidden' => 1),
      'varunits' => array('name'=>'varunits','hidden' => 1),
      'startdate' => array('name'=>'startdate','hidden' => 1),
      'enddate' => array('name'=>'enddate','hidden' => 1),
      'editlink' => array('name'=>'editlink','hidden' => 1),
      'addlink' => array('name'=>'addlink','hidden' => 1),
      'deletelink' => array('name'=>'deletelink','hidden' => 1),
    );
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    // this applies to a cat_mp property.  The 
    // SIC code will be stored as propcode
    // corresponding to the sub-list of MP ftype
    // if $row->ftype exists 
    //dpm($row,'row before');
    if (empty($row->{$this->row_map['code']})) {
      // we need to query the parent for this
      $parent = entity_load_single($row->entity_type, $row->featureid);
      $facref = field_get_items('dh_feature', $parent, 'dh_link_facility_mps');
      if (!empty($facref)) {
        $to = array_shift($facref);
        $fac = entity_load_single('dh_feature', $to['target_id']);
        $row->{$this->row_map['code']} = $fac->ftype;
      }
    }
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#weight' => 9,
      '#options' => dh_wsp_get_sic_cats(),
      '#default_value' => $row->{$this->row_map['code']},
      '#ajax' => array(
        'callback' => 'dh_vwuds_sic_options',
        'wrapper' => 'update-sic-options',
      ),
      // we set this as pre-validated because otherwise, updating form options
      // via ajax causes a conflict that makes validation fail.
      // this, however, creates the problem of no validation, which might 
      // better be handled in a custom function where we find the state of the propcode var
      // and re-make the options list of this element during form handling, and then submit to 
      // validation, which should proceed appropriately.
      '#needs_validation' => FALSE,
      '#validated' => TRUE,
    );
    //dpm($row,'row after');
    $rowform[$this->row_map['value']] = array(
      '#type' => 'select',
      '#weight' => 10,
      '#options' => !empty($row->{$this->row_map['code']}) ? dh_wsp_get_sic_options(dh_wsp_translate_mpcats($row->{$this->row_map['code']})) : dh_wsp_get_sic_options(dh_wsp_translate_mpcats('agriculture')),
      '#default_value' => $row->{$this->row_map['value']},
      // we set this as pre-validated because otherwise, updating form options
      // via ajax causes a conflict that makes validation fail.
      // this, however, creates the problem of no validation, which might 
      // better be handled in a custom function where we find the state of the propcode var
      // and re-make the options list of this element during form handling, and then submit to 
      // validation, which should proceed appropriately.
      '#needs_validation' => FALSE,
      '#validated' => TRUE,
      '#prefix' => "<div id='update-sic-options'>",
      '#suffix' => "</div>",
    );
    $hidden = array('pid', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}
?>