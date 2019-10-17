<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHQuantregParamsTimespan extends dHVariablePluginDefault {
  
public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $rowform[$this->row_map['code']] = array(
      '#type' => 'textfield',
      '#default_value' => $row->{$this->row_map['code']},
      '#weight' => 1,
      '#description' => 'Analysis Timespan (Propcode)',
    );
	//dpm($rowform);
	
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  

  	public function save(&$entity) {
	$propcode = $entity->propcode;
	  if ($propcode != 'full'){
	//print_r($propcode);
	$code_explode = explode("-",$propcode);
	$startdate = $code_explode[0]; 
	$enddate = $code_explode[1]; 		
	$startdate = $startdate."-01-01";
	$enddate = $enddate."-12-31";
	dpm("startdate", $startdate);
	dpm("enddate", $enddate);
		 
		$entity->startdate = $startdate;
		$entity->enddate = $enddate;
	  }
     }
}


?>