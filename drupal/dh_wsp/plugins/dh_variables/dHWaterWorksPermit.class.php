<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHVDHPumpCapacity extends dHVariablePluginDefault {
 
  public function hiddenFields() {
    $hidden = array('pid', 'propcode', 'startdate','enddate','featureid', 'entity_type', 'propname', 'varid', 'dh_link_admin_pr_condition',) + parent::hiddenFields();
    return $hidden;
  }
  
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    // do nothing - subclasses control form elements with this function
    //$this->hideFormRowEditFields($rowform);
    $rowform['propvalue']['#title'] = 'Maximum Pumping Capacity.';
    $rowform['propvalue']['#description'] = 'Intake or pump station maximum capacity.';
    $rowform['proptext']['und'][0]['value']['#title'] = 'Comments.';
    $rowform['proptext']['#weight'] = 5;
  }
  
}

?>