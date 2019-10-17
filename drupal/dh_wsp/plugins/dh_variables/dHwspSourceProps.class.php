<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHwspSourceType extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'propname', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'gw' => 'Groundwater',
      'sw' => 'Surface Water',
	  'res' => 'Reservoir',
	  'pw' => 'Purchased Water'
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Select Source Type if above is incorrect, or has changed',
      '#title' => 'Source Type'
    );

    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
      
  }
  
}

  
class dHwspSourceWellCasingDepth extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Well Casing Depth (ft)');
	$rowform['#weight']=13;
  }  
}

class dHwspSourceWellDepth extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Well Depth (ft)');
	$rowform['#weight']=12;
  }  
}

class dHwspSourceWellDiameter extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Well Diameter (in)');
	$rowform['#weight']=11;
  }  
}

class dHwspSourceAvgDailyUse extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Average Daily Use (mgd)');
	$rowform['#weight']=2;
  }  
}

class dHwspSourcePermitDailyMax extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Permit Daily Max (mgd)');
	$rowform['propvalue']['#description'] = t('DEQ Permit Daily Max (mgd)');
	$rowform['#weight']=50;
  }  
}

class dHwspSourcePermitMonthlyMax extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Permit Monthly Max (mgmo)');
	$rowform['propvalue']['#description'] = t('DEQ Permit Monthly Max (mgmo)');
	$rowform['#weight']=51;
  }  
}

class dHwspSourcePermitAnnualMax extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Permit Annual Max (mgy)');
	$rowform['propvalue']['#description'] = t('DEQ Permit Annual Max (mgy)');
	$rowform['#weight']=52;
  }  
}

class dHwspSourceWaterbodyStorage extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Waterbody Storage (mg)');
	$rowform['#weight']=30;
  }  
}

class dHwspSourceDrainageArea extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Drainage Area Above Intake or Dam (sqmi)');
	$rowform['#weight']=23;
  }  
}

class dHwspSourcePumpStationCap extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Pump Station Capacity (mgd)');
	$rowform['#weight']=21;
  }  
}

class dHwspSourceSafeYield extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Safe Yield (mgd)');
	$rowform['#weight']=22;
  }  
}

class dHwspSourceHistoricLowFlow extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Historic Low Flow (cfs)');
	$rowform['#weight']=24;
  }  
}

class dHwspSourceDesignCapacityAvg extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Source Average Withdrawal Design Capacity (mgd)');
	$rowform['#weight']=3;
  }  
} 

class dHwspSourceDesignCapacityMax extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Source Maximum Withdrawal Design Capacity (mgd)');
	$rowform['#weight']=4;
  }  
} 

class dHwspWTPCapacityMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Water Treatment Plant Capacity (mgd)');
	$rowform['#weight']=5;
  }  
} 

class dHwspSourceDEQWellID extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#title'] = t('DEQ Well Number');
    $rowform['propvalue']['#type'] = 'hidden';
	$rowform['#weight']=5;
  }  
} 

?>
