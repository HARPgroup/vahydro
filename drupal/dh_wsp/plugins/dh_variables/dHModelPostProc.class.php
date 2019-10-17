<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHModelPostProcElid extends dHVariablePluginDefault {
  
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
      '#description' => 'Element ID',
    );
    $rowform['#weight']=1;

	  
//	  function form_example_form_validate(&$rowform, $row){
//		  if (!is numeric($row['values']['code'])){
//			  form_set_error('code',t('You must enter a valid number'));
//			  return FALSE;
//		  }
//		  return TRUE;
//	  }
	  
	  
	  
	  
	  
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHModelPostProcRunid extends dHVariablePluginDefault {
  
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
      '#description' => 'Run ID',
    );
    $rowform['#weight']=2;

	  
//	  function form_example_form_validate(&$rowform, $row){
//		  if (!is numeric($row['values']['code'])){
//			  form_set_error('code',t('You must enter a valid number'));
//			  return FALSE;
//		  }
//		  return TRUE;
//	  }
	  
	  
	  
	  
	  
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}



?>
