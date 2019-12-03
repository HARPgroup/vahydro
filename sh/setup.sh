#!/bin/sh

rm -Rf /var/www/html/d.alpha/modules/dh_modflow
ln -s /opt/model/vahydro/drupal/dh_modflow/ /var/www/html/d.alpha/modules/dh_modflow

rm -Rf /var/www/html/d.alpha/modules/dh_vbo
ln -s /opt/model/vahydro/drupal/dh_vbo/ /var/www/html/d.alpha/modules/dh_vbo
