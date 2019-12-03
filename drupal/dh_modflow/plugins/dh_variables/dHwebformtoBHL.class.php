<?php
module_load_include('inc', 'dh', 'plugins/dh.display');
module_load_include('module', 'dh_vbo');
class dHwebformtoBHL extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
   public function update(&$entity) {
	 parent::update($entity);
	 $converter = new ViewsBulkOperationsDHProp2BHL;
     $converter->migrate($entity);  
   }
}


  
?>
