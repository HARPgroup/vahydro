# Use custom libPaths ??
# See setup info at https://github.com/HARPgroup/vahydro/wiki/R-setup 
#  - if we set .Renviron in /var/www/R to have this path, we may not need this libPaths command here since it should automatically be set 
#    when we run R from /var/www/R 
#.libPaths( c( "/var/www/R/x86_64-pc-linux-gnu-library" , .libPaths() ) )

# Set up R packages
install.packages('ggplot2');
install.packages('gtable');
install.packages('reshape2');
install.packages('RJSONIO');
install.packages('data.table');
install.packages('zoo');
install.packages('stringr');
install.packages('lubridate');
#install.packages("R.rsp")
# quantreg and hydroTSM failed at first on Ubuntu 20.04
# even with added repository 
# Note, conquer needs liblapack-dev, so need to:
#  sudo apt install liblapack-dev (see also: system config notes)
install.packages("conquer")
install.packages("quantreg")
install.packages('hydroTSM');
install.packages('scales');
install.packages('rgeos');
install.packages('ggrepel');
install.packages('ggpmisc');
install.packages('ggsn');
install.packages('RCurl');
install.packages('dataRetrieval');
install.packages('sqldf');
install.packages('PearsonDS');
install.packages('rlist');
install.packages("lfstat")
install.packages("pander")
# rlang seems to need to be updated if the R version is updated in an existing install?
install.packages('rlang')
# after installing rlang, which upgrades it, you have to quit R, then go back in and load rlang before installing devtools
library('rlang')
install.packages('devtools')
library('devtools')
install_github("HARPgroup/hydro-tools")
#install.packages('IHA');
install_github("jasonelaw/iha")
# Test a different way of doing this:
# Instead of sudo www-data to do these installs, we may be able to specify the lib like so:
# install.packages('sqldf', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# But for some reason it does not work...
# I *think* it's cause we should be doing: lib='/var/www/R/x86_64-pc-linux-gnu-library/3.6'
# But would need to test next time around.