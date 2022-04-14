#!/user/bin/env drush
<?php

// Calling:
// cd /var/www/html/d.dh/
// drush scr modules/dh_ows_views/src/import_precip_summary.php
$importer_id = 'dmtf_precip_status';
$csvfile_path = 'http://deq1.bse.vt.edu/d.dh/va-dmtf-precip';
// load feeds importer
$source = feeds_source($importer_id);
// Load the source fetcher config.
$fetcher_config = $source->getConfigFor($source->importer->fetcher);
$fetcher_config['source'] = $csvfile_path;
$source->setConfigFor($source->importer->fetcher, $fetcher_config);
// Tweak the importer configuration, to enable "Process in the background".
$config = array(
  'process_in_background' => TRUE,
);
$source->importer->addConfig($config);


$source->save();
$source->startImport();

?>
