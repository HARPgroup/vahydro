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
# mapserv
rm /var/www/html/mapserv/vahydro_drought_mllr-live.map
ln -s /opt/model/vahydro/mapserv/vahydro_drought_mllr-live.map /var/www/html/mapserv/vahydro_drought_mllr-live.map
rm /var/www/html/mapserv/vahydro_drought_wms.map
ln -s /opt/model/vahydro/mapserv/vahydro_drought_wms.map /var/www/html/mapserv/vahydro_drought_wms.map
rm /var/www/html/mapserv/dh_wfs.map
ln -s /opt/model/vahydro/mapserv/dh_wfs.map /var/www/html/mapserv/dh_wfs.map
rm /var/www/html/mapserv/dh_feature_basemap.map
ln -s /opt/model/vahydro/mapserv/dh_feature_basemap.map /var/www/html/mapserv/dh_feature_basemap.map


# add drought and cbp6 to R directory
ln -s /opt/model/vahydro/drupal/dh_drought/src/r/ /var/www/R/drought
ln /opt/model/cbp6/ /var/www/R/cbp6 -s

ln -s /usr/local/src/drush/drush /usr/bin/drush

chown www-data -Rf /var/www/html/d.dh/sites/default/files
chown www-data -Rf /var/www/html/d.bet/sites/default/files
chown www-data -Rf /var/www/html/d.alpha/sites/default/files


# model data directories are mounted via NAS, defined in /etc/fstab 
# model output data *.log files go here
# phase 6 data for runoff and phase 5 runoff cache files like /media/model/p6/vahydro/runoff/TU3_9230_9260.vahydro.cbp532.log
sudo mount dbase2:/media/model
