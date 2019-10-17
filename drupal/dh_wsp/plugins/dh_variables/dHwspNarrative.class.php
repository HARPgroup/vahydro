<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

 
class dHwspProjectedDeficit extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
	$rowform['propvalue']['#title'] = t('Edit This Propvalue');
    $rowform['propcode']['#title'] = t('Edit This Propcode');
    $rowform['proptext']['#title'] = t('Projected Deficit Summary');
	$rowform['#weight']=1;
  }  
}


?>
