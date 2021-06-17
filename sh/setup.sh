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

# Set up R 
sudo mkdir /var/www/R
sudo chown www-data:modelers /var/www/R
sudo -u www-data mkdir /var/www/R/x86_64-pc-linux-gnu-library
# now cd to /var/www/R and run the scripts in setup_vahydro_packages.R as www-data user