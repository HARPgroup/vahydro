# Set up R packages
install.packages('ggplot2');
install.packages('gtable');
install.packages('reshape2');
install.packages('RJSONIO');
install.packages('data.table');
install.packages('zoo');
install.packages('IHA');
install.packages('stringr');
install.packages('lubridate');
install.packages('scales');
install.packages('hydroTSM');
install.packages("quantreg")
install.packages('rgeos');
install.packages('ggrepel');
install.packages('ggpmisc');
install.packages('ggsn');
install.packages('RCurl');
install.packages('dataRetrieval');
install.packages('devtools')
library('devtools')
install_github("HARPgroup/hydro-tools")
# Test a different way of doing this:
install.packages('sqldf');
# Instead of sudo www-data to do these installs, we may be able to specify the lib like so:
# install.packages('sqldf', lib='/var/www/R/x86_64-pc-linux-gnu-library/');
# But for some reason it does not work...
# I *think* it's cause we should be doing: lib='/var/www/R/x86_64-pc-linux-gnu-library/3.6'
# But would need to test next time around.