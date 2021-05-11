#!/bin/sh

#************************
# On live server
#************************
rm -Rf /var/www/html/d.dh/modules/om
ln -s /opt/model/om/drupal/om/ /var/www/html/d.dh/modules/om
rm -Rf /var/www/html/d.dh/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ /var/www/html/d.dh/modules/dh_modflow
rm -Rf /var/www/html/d.dh/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ /var/www/html/d.dh/modules/dh_vbo
rm -Rf /var/www/html/d.dh/modules/dh_wsp
ln -s /opt/model/vahydro/drupal/dh_wsp/ /var/www/html/d.dh/modules/dh_wsp
# Drought
rm -Rf /var/www/html/d.dh/modules/dh_drought
ln -s /opt/model/vahydro/drupal/dh_drought/ /var/www/html/d.dh/modules/dh_drought

#************************
# On alpha server 
#************************
# modflow
rm -Rf /var/www/html/d.alpha/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ /var/www/html/d.alpha/modules/dh_modflow
# vbo
rm -Rf /var/www/html/d.alpha/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ /var/www/html/d.alpha/modules/dh_vbo
# wsp
rm -Rf /var/www/html/d.alpha/modules/dh_wsp
ln -s /opt/model/vahydro/drupal/dh_wsp/ /var/www/html/d.alpha/modules/dh_wsp
# drought 
rm -Rf /var/www/html/d.alpha/modules/dh_drought
ln -s /opt/model/vahydro/drupal/dh_drought/ /var/www/html/d.alpha/modules/dh_drought

ln -s /opt/model/vahydro/drupal/dh_drought/src/r/ /var/www/R/drought

# set up drush? 
ln -s /home/rob/.config/composer/vendor/bin/drush /usr/bin/drush

chown www-data -Rf /var/www/html/d.dh/sites/default/files
chown www-data -Rf /var/www/html/d.bet/sites/default/files
chown www-data -Rf /var/www/html/d.alpha/sites/default/files