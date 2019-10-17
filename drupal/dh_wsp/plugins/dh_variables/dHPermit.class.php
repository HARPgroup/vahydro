<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHPermitExemptionCode extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
	  '0' => '0 - NA',
	  '1' => '1 - Grandfathered Exempt',
	  '2' => '2 - Valid Exemption - Other',
	  '3' => '3 - Add-info - Need Date',
	  '4' => '4 - Add-Info - Other',
	  '5' => '5 - No Response'
    );
    $rowform[$this->row_map['value']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['value']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Code',
    );
    $rowform['#weight']=1;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;

  }
 
}
?>
