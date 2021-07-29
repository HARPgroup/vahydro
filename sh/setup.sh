#!/bin/sh

# link drupal modules in various directories/servers
module_path="/var/www/html/d.alpha"
rm -Rf $module_path/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ $module_path/modules/dh_modflow
rm -Rf $module_path/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ $module_path/modules/dh_vbo
rm -Rf $module_path/modules/dh_wsp
ln -s /opt/model/vahydro/drupal/dh_wsp/ $module_path/modules/dh_wsp
rm -Rf $module_path/modules/dh_drought
ln -s /opt/model/vahydro/drupal/dh_drought/ $module_path/modules/dh_drought

# add drought to R directory
ln -s /opt/model/vahydro/drupal/dh_drought/src/r/ /var/www/R/drought

ln -s /usr/local/src/drush/drush /usr/bin/drush

chown www-data -Rf /var/www/html/d.dh/sites/default/files
chown www-data -Rf /var/www/html/d.bet/sites/default/files
chown www-data -Rf /var/www/html/d.alpha/sites/default/files