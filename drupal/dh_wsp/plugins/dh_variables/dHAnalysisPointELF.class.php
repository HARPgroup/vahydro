<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHAnalysisPointBiometric extends dHVariablePluginDefault {
  
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
	  'aqbio_nt_total' => 'Number of Taxa, Total Fish',
	  'aqbio_benthic_nt_total' => 'Number of Taxa, Total Benthic',
	  'aqbio_nt_benins' => 'Number of Taxa, Benthic Insectivores',
	  'aqbio_nt_native' => 'Number of Taxa, Native Fish',
	  'aqbio_nt_sunfish' => 'Number of Taxa, Sunfish',
	  'aqbio_nt_minnow' => 'Number of Taxa, Minnows',
	  'aqbio_benthic_nt_ept' => 'Number of Taxa, EPT Benthic',
	  'aqbio_benthic_nt_tol' => 'Number of Taxa, Tolerant Benthic',
	  'aqbio_benthic_nt_intol' => 'Number of Taxa, Intolerant Benthic',
	  'aqbio_benthic_nt_ephem' => 'Number of Taxa, Ephemeroptera',
	  'aqbio_nt_cent' => 'Number of Taxa, Centrarchidae',
	  'aqbio_nt_cent_native' => 'Number of Taxa, Native Centrarchidae',
	  'aqbio_nt_cypr_native' => 'Number of Taxa, Native Cyprinidae',
	  'aqbio_nt_native_benth' => 'Number of Taxa, Native Benthic Specialized Fish',
	  'aqbio_nt_darter' => 'Number of Taxa - darter',
	  'aqbio_nt_bival' => 'Number of Taxa - Bivalvia',
 	  'aqbio_ni_total' => 'Number of Individuals, Total Fish',
	  'aqbio_benthic_ni_total' => 'Number of Individuals, Total Benthic',
	  'aqbio_pi_benthic_chiro' => 'percent individuals, Chironomidae',
	  'aqbio_pi_ephem_tri_nohydro' => 'percent individuals - Ephemeroptera and Tricoptera (no Hydropsychidae)',
	  'aqbio_pi_baet2ephem' => 'percent individuals - Baetidae to Ephemperoptera',
	  'aqbio_pi_nonins' => 'percent individuals - non Insecta',
	  'aqbio_pi_benthic_dominant01' => 'percent individuals - dominant 01 taxon, benthic',
	  'aqbio_pi_ephem' => 'percent individuals - Ephemeroptera',
	  'aqbio_pi_intol' => 'percent individuals - intolerant (xxx)',
	  'aqbio_pi_rbs' => 'percent individuals - round-bodied suckers',
	  'aqbio_pi_lithophil' => 'percent individuals - lithophils',
	  'aqbio_pi_ept' => 'percent individuals - EPT',
	  'aqbio_pi_coleo' => 'percent individuals - Coleoptera',
	  'aqbio_pi_cllct' => 'percent individuals - collector',
	  'aqbio_pi_filtr' => 'percent individuals - filterer',
	  'aqbio_pi_insct' => 'percent individuals insectivore',
	  'aqbio_pi_inscyp' => 'percent insectivorous cyprinidae',
	  'aqbio_pi_omn' => 'percent individuals omnivorous',
	  'aqbio_pi_invtpisc' => 'percent individuals - invertivore and piscivore',
	  'aqbio_pi_flow_fast' => 'percent individuals - flow preference, fast',
	  'aqbio_pi_flow_mod' => 'percent individuals - flow preference, moderate',
	  'aqbio_pi_flow_slow' => 'percent individuals - flow preference, slow',
	  'aqbio_pi_native' => 'percent individuals native',
	  'aqbio_pi_nonnat' => 'percent individuals non-native',
	  'aqbio_pi_dominant01' => 'percent individuals - dominant 01 taxon, fish',
	  'aqbio_mf_evenness' => 'Evenness (fish)',
	  'aqbio_mb_evenness' => 'Evenness (benthic)',
	  'aqbio_benthic_mmi_sci_fam' => 'Stream Condition Index (family)' 
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Biometric',
    );
    $rowform['#weight']=1;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;

  }
  
}

class dHAnalysisPointFlowmetric extends dHVariablePluginDefault {
  
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
      'nhdp_drainage_sqkm' => 'Drainage Area (sqkm)',
      'erom_q0001e_mean' => 'Annual Mean Flow (cfs)',
      'erom_q0001e_jan' => 'January Mean Flow (cfs)',
      'erom_q0001e_feb' => 'February Mean Flow (cfs)',
      'erom_q0001e_mar' => 'March Mean Flow (cfs)',
      'erom_q0001e_apr' => 'April Mean Flow (cfs)',
      'erom_q0001e_may' => 'May Mean Flow (cfs)',
      'erom_q0001e_june' => 'June Mean Flow (cfs)',
      'erom_q0001e_july' => 'July Mean Flow (cfs)',
      'erom_q0001e_aug' => 'August Mean Flow (cfs)',
      'erom_q0001e_sept' => 'September Mean Flow (cfs)',
      'erom_q0001e_oct' => 'October Mean Flow (cfs)',
      'erom_q0001e_nov' => 'November Mean Flow (cfs)',
      'erom_q0001e_dec' => 'December Mean Flow (cfs)'
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Flowmetric',
    );
    $rowform['#weight']=3;

    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHAnalysisPointPctFlowReduction extends dHVariablePluginDefault {
  
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
      '#description' => 'Percent Reduction in Flowmetric',
    );
    $rowform['#weight']=4;

	  
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

class dHAnalysisPointRegion extends dHVariablePluginDefault {
  
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
      'nhd_huc6' => 'HUC 6',
      'nhd_huc8' => 'HUC 8',
	  'nhd_huc10' => 'HUC 10',
      'nhd_huc12' => 'HUC 12',
	  'hwi_region' => 'HWI Region',
      'ecoregion_iii' => 'Ecoregion III',
	  'ecoregion_iv' => 'Ecoregion IV',
	  'ecoiii_huc6' => 'Ecoregion III - HUC 6 Intersection'
	  
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Containing Region',
    );
    $rowform['#weight']=5;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHAnalysisPointSampres extends dHVariablePluginDefault {
  
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
      'species' => 'Species (Fish metrics only)',
      'maj_fam_gen_spec' => 'Family/Genus/Species (Benthics only)',
	  'maj_fam_gen' => 'Family/Genus (Benthics only)',
      'maj_fam' => 'Family (Benthics only)',
	  'maj_species' => 'Species (Benthics only)'
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Sample Resolution',
    );
    $rowform['#weight']=2;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('pid', 'propvalue','startdate', 'enddate', 'featureid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
    }
    $rowform[$this->row_map['value']]['#size'] = 1;
    
  }
  
}

class dHAnalysisPointMethod extends dHVariablePluginDefault {
  
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
      'elf_quantreg' => 'Static Drainage Area Threshold',
      'elf_quantreg_pwit' => 'Piecewise Iterative Function',
    );
    $rowform[$this->row_map['code']] = array(
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->{$this->row_map['code']},
      '#size' => 1,
      '#weight' => 1,
      '#description' => 'Breakpoint Detection Method',
    );
    $rowform['#weight']=10;
      
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
