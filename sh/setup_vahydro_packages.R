# Set up R packages
# Must now do this:
.libPaths( c( "/var/www/R/x86_64-pc-linux-gnu-library" , .libPaths() ) )

install.packages('ggplot2', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('gtable', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('reshape2', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('RJSONIO', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('data.table', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('zoo', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('PearsonDS', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('jpeg', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('lfstat', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('dplyr', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# can try this, but failed as of 6/8/2021
install.packages('IHA', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# Instead this may work (but also failed as of 6/8/2021):
install.packages("IHA", repos="http://R-Forge.R-project.org", lib='/var/www/R/x86_64-pc-linux-gnu-library/')
# This *worked* 6/8/2021
devtools::install_github("jasonelaw/iha", lib='/var/www/R/x86_64-pc-linux-gnu-library/')

install.packages('stringr', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('lubridate', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('scales', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('hydroTSM', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages("quantreg", lib='/var/www/R/x86_64-pc-linux-gnu-library/')
install.packages('rgeos', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('ggrepel', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('ggpmisc', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('ggnewscale', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('ggsn', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('RCurl', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('httr', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('pander', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('dataRetrieval', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
install.packages('rlist', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# IN Ubtuntu 20.04 we Needed to cinstall devtools globally which was as simple as:
sudo apt install r-cran-devtools
# Then rerun R as www-data 
library('devtools')
install_github("HARPgroup/hydro-tools", lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# Test a different way of doing this:
install.packages('sqldf', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# Instead of sudo www-data to do these installs, we may be able to specify the lib like so:
# install.packages('sqldf', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# But for some reason it does not work...
# I *think* it's cause we should be doing: lib='/var/www/R/x86_64-pc-linux-gnu-library/3.6'
# But would need to test next time around.