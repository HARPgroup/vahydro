<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHvwudsreportsquarterly extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propcode', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      '0' => 'No',
      '1' => 'Yes',

    );
    $rowform[$this->row_map['value']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['value']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'Reports Quarterly?'
    );

    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propcode','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['code']]['#size'] = 1;
	$rowform['#weight']=1;      
    
  }
  
}
  
class dHvwudsreportingmethod extends dHVariablePluginDefault {
  
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
      'email' => 'Email',
      'mail' => 'Mail',

    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'Reporting Method'
    );
      
    
  }
  
}

class dHvwudsinsidegwma extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propcode', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      '0' => 'No',
      '1' => 'Yes',

    );
    $rowform[$this->row_map['value']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['value']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'Inside GWMA?'
    );
      
    
  }
  
}

?>
