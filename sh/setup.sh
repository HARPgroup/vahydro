#!/bin/sh

rm -Rf /var/www/html/d.alpha/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ /var/www/html/d.alpha/modules/dh_modflow

rm -Rf /var/www/html/d.alpha/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ /var/www/html/d.alpha/modules/dh_vbo

rm -Rf /var/www/html/d.alpha/modules/dh_wsp
ln -s /opt/model/vahydro/drupal/dh_wsp/ /var/www/html/d.alpha/modules/dh_wsp

rm -Rf /var/www/html/d.alpha/modules/dh_drought
ln -s /opt/model/vahydro/drupal/dh_drought/ /var/www/html/d.alpha/modules/dh_drought

ln -s /opt/model/vahydro/drupal/dh_drought/src/r/ /var/www/R/drought

ln -s /usr/local/src/drush/drush /usr/bin/drush

chown www-data -Rf /var/www/html/d.dh/sites/default/files
chown www-data -Rf /var/www/html/d.bet/sites/default/files
chown www-data -Rf /var/www/html/d.alpha/sites/default/files