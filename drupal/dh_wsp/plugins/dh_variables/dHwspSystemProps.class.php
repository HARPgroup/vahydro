<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHwspComplianceCondition extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }

  public function formRowEdit(&$rowform, $row) {
    global $user; // this loads an object with the current logged in user info
	

   // check if this user is type wsp user (non-privileged to change status to "Complete")
    if (in_array('wsp user', $user->roles)) {		
	
		if ($row->{$this->row_map['code']} == 'Complete') {
			$options = array(
			'Complete' => 'Complete',
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		} else {
			$options = array(
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		}
		
	} else {
		$options = array(
	   'Complete' => 'Complete',
       'Incomplete' => 'Incomplete',
       'Pending' => 'Pending DEQ Review',
       'Submitted' => 'Submit to DEQ'
		);
	}	

    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $options,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'Compliance Condition Status'	  
    );

		$rowform['actions'][submit] = array(
		'#type' => submit,
		'#value' => t('Save'),
		'#weight' => 40,
		);
	
		$rowform['actions'][delete] = array(
		'#type' => hidden,
		'#value' => t('Delete Compliance Condition Status Property'),
		'#weight' => 45,
		);
	
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHwspSystemComplianceStatus extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }

  public function formRowEdit(&$rowform, $row) {
    global $user; // this loads an object with the current logged in user info

   // check if this user is type wsp user (non-privileged to change status to "Complete")
    if (in_array('wsp user', $user->roles)) {		
	
		if ($row->{$this->row_map['code']} == 'Complete') {
			$options = array(
			'Complete' => 'Complete',
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		} else {
			$options = array(
			null => 'Select Status',
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		}
		
	} else {
		$options = array(
	   null => 'Select Status',
	   'Complete' => 'Complete',
       'Incomplete' => 'Incomplete',
       'Pending' => 'Pending DEQ Review',
       'Submitted' => 'Submit to DEQ'
		);
	}

    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $options,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'WSP System Compliance Status'
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHwspSourceComplianceStatus extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }

  public function formRowEdit(&$rowform, $row) {
    global $user; // this loads an object with the current logged in user info

   // check if this user is type wsp user (non-privileged to change status to "Complete")
    if (in_array('wsp user', $user->roles)) {		
	
		if ($row->{$this->row_map['code']} == 'Complete') {
			$options = array(
			'Complete' => 'Complete',
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		} else {
			$options = array(
			null => 'Select Status',
			'Incomplete' => 'Incomplete',
			'Submitted' => 'Submit to DEQ'
			);
		}
		
	} else {
		$options = array(
	   null => 'Select Status',
	   'Complete' => 'Complete',
       'Incomplete' => 'Incomplete',
       'Pending' => 'Pending DEQ Review',
       'Submitted' => 'Submit to DEQ'
		);
	}

    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $options,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'WSP Source Compliance Status'
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}


class dHwspCurrentDisaggregatedUse extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'Commercial' => 'Commercial',
      'Heavy Industrial' => 'Heavy Industrial',
	  'Military' => 'Military',
	  'Other' => 'Other',
	  'Process Loss' => 'Process Loss',
	  'Residential' => 'Residential',
	  'Sales to Other CWS' => 'Sales to Other CWS',
	  'Unaccounted Loss' => 'Unaccounted Loss'
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => '',
      '#title' => 'Disaggregated Use Type'
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Disaggregated Use (mgd)');
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}
  
class dHwspCurrentUseMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Current Withdrawal (mgd)');
  }  
}
 
class dHwspCoolingReturnMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Cooling Return (mgd)');
  }  
}

class dHwspMaxWithdrawalMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Maximum Daily Withdrawal (mgd)');
  }  
}

class dHwspPerCapitaUse extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Per Capita Use (gpd)');
  }  
}


class dHwspGroundwaterSources extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Groundwater Sources');
  }  
}

class dHwspSurfaceWaterSources extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Surface Water Sources');
  }  
}

class dHwspCurrentGWCapacityMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Current Groundwater Withdrawal Capacity (mgd)');
	$rowform['#weight']=10;

  }  
}

class dHwspCurrentSWCapacityMGD extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Current Surface Water Withdrawal Capacity (mgd)');
	$rowform['#weight']=20;
  }  
}

class dHwspMaxAnnualUseMGY extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Maximum Annual Withdrawal (MGY)');
  }  
}

class dHwspNumBusinessConnections extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Business Connections');
  }  
}


class dHwspPopulationServed extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Total Population Served');
  }  
}

class dHwspNumberConnections extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Service Connections');
  }  
}

class dHwspResidencesServed extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Residences Served');
  }  
}

class dHwspVDHPermitLimit extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('VDH Permit Limit (MGD)');
  }  
}

class dHwspEstimatedAnnualUse extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Average Annual Water Use  (MGY)');
  }  
}

class dHwspSMSSUUseInCWS extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Average Annual Water Withdrawal (MGY) of Small Self-Supplied Groundwater Users inside Service Area');
  }  
}

class dHwspSMSSUINCWS extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Number of Small Self-Supplied Groundwater Users inside Service Area');
  }  
}


class dHwspInCWSServiceArea extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('pid', 'propvalue', 'startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'outside' => 'No',
      'inside' => 'Yes',

    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Select Yes if this system is within a Community Water System service area',
      '#title' => 'Inside Community Water System Service Area?'
    );

    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle', 'proptext', 'dh_link_admin_pr_condition');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
      
  }
  
}

class dHwspFuturePurchasedWater extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Future Average Annual Purchased Water (MGD)');
  }  
}

class dHwspCurrentPurchasedWater extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Current Average Annual Purchased Water (MGD)');
  }  
}

class dHwspMaxDailyPurchase extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Maximum Daily Purchased Water (MGD)');
  }  
}

class dHwspWaterSold extends dHVariablePluginDefault {
  public function formRowEdit(&$rowform, $row) {
    parent::formRowEdit($rowform, $row);
    $rowform['propcode']['#type'] = 'hidden';
    $rowform['dh_link_admin_pr_condition']['#type'] = 'hidden';
    $rowform['propvalue']['#title'] = t('Water Sold (MGD)');
  }  
}

?>
