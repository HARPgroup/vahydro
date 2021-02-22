#!/bin/sh

rm -Rf /var/www/html/d.alpha/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ /var/www/html/d.alpha/modules/dh_modflow

rm -Rf /var/www/html/d.alpha/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ /var/www/html/d.alpha/modules/dh_vbo

rm -Rf /var/www/html/d.alpha/modules/dh_wsp
ln -s /opt/model/vahydro/drupal/dh_wsp/ /var/www/html/d.alpha/modules/dh_wsp

rm -Rf /var/www/html/d.alpha/modules/dh_drought
ln -s /opt/model/vahydro/drupal/dh_drought/ /var/www/html/d.alpha/modules/dh_drought

