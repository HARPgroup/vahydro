# go into crontab edit mode
crontab -e
# add the following lines to the crontab 
@reboot sleep 300 && /opt/model/om/sh/startup.model_scratch.sh 12
@reboot sleep 300 && /opt/model/om/sh/startup.model_sessiondata.sh 12
