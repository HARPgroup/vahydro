# FLOW EXCEEDANCE SCENARIO COMPARISON PLOT

# Setup
basepath <- '/var/www/R'
setwd(basepath)
source(paste(basepath,"config.local.private", sep = "/"))
source(paste0(cbp6_location,"/code/cbp6_functions.R"))
source(paste0(github_location, "/auth.private"));
source(paste(cbp6_location, "/code/fn_vahydro-1.0.R", sep = ''))
site <- "http://deq2.bse.vt.edu/d.dh"
token <- rest_token(site, token, rest_uname, rest_pw)

# INPUTS
riv.seg <- 'YM3_6430_6620'
start.date <- '1991-01-01'
end.date <- '2000-12-31'
cn11 <- '1: 2020 Demand' #labels for the plot
cn18 <- '2: Exempt Withdrawals'
cn15 <- '3: CC 10/10'
cn14 <- '4: CC 50/50'
cn16 <- '5: CC 90/90'
cn13 <- '6: 2040 Demand'

# Downloading flow data
data11 <- vahydro_import_data_cfs(riv.seg, '11', token, site, start.date, end.date)
data18 <- vahydro_import_data_cfs(riv.seg, '18', token, site, start.date, end.date)
data15 <- vahydro_import_data_cfs(riv.seg, '15', token, site, start.date, end.date)
data14 <- vahydro_import_data_cfs(riv.seg, '14', token, site, start.date, end.date)
data16 <- vahydro_import_data_cfs(riv.seg, '16', token, site, start.date, end.date)
data13 <- vahydro_import_data_cfs(riv.seg, '13', token, site, start.date, end.date)

# Determining the "rank" (0-1) of the flow value
num_observations <- as.numeric(length(data11$date))
rank_vec <- as.numeric(c(1:num_observations))

# Calculating exceedance probability
prob_exceedance <- 100*((rank_vec) / (num_observations + 1))

exceed_scenario11 <- sort(data11$flow, decreasing = TRUE, na.last = TRUE)
exceed_scenario18 <- sort(data18$flow, decreasing = TRUE, na.last = TRUE)
exceed_scenario15 <- sort(data15$flow, decreasing = TRUE, na.last = TRUE)
exceed_scenario14 <- sort(data14$flow, decreasing = TRUE, na.last = TRUE)
exceed_scenario16 <- sort(data16$flow, decreasing = TRUE, na.last = TRUE)
exceed_scenario13 <- sort(data13$flow, decreasing = TRUE, na.last = TRUE)

scenario11_exceedance <- quantile(exceed_scenario11, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)
scenario18_exceedance <- quantile(exceed_scenario18, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)
scenario15_exceedance <- quantile(exceed_scenario15, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)
scenario14_exceedance <- quantile(exceed_scenario14, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)
scenario16_exceedance <- quantile(exceed_scenario16, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)
scenario13_exceedance <- quantile(exceed_scenario13, probs = c(0.01, 0.05, 0.5, 0.95, 0.99), na.rm = TRUE)

# Determining max flow value for exceedance plot scale
max <- max(c(max(scenario11_exceedance), max(scenario18_exceedance),
             max(scenario15_exceedance), max(scenario14_exceedance),
             max(scenario16_exceedance), max(scenario13_exceedance)), na.rm = TRUE);

min <- min(c(min(scenario11_exceedance), min(scenario18_exceedance),
             min(scenario15_exceedance), min(scenario14_exceedance),
             min(scenario16_exceedance), min(scenario13_exceedance)), na.rm = TRUE);

# Rounding used for scaling of plot axes

if (max > 10000){
  max <- 100000
}else if (max > 1000){
  max <- 10000
}else if (max > 100){
  max <- 1000
}else if (max > 10){
  max <- 100
}else {
  max <- 10
}

if (min>100){
  min<-100
}else if (min>10){ 
  min<-10
}else{
  min<-1
}

if (min==100){
  fixtheyscale<- scale_y_continuous(trans = log_trans(), 
                                    breaks = c(100, 1000, 10000, 100000), 
                                    limits=c(min,max))
}else if (min==10){
  fixtheyscale<- scale_y_continuous(trans = log_trans(), 
                                    breaks = c(10, 100, 1000, 10000), 
                                    limits=c(min,max))
}else if (min==1){
  fixtheyscale<- scale_y_continuous(trans = log_trans(), 
                                    breaks = c(1, 10, 100, 1000, 10000), 
                                    limits=c(min,max))
}else{
  fixtheyscale<- scale_y_continuous(trans = log_trans(), breaks = base_breaks(), 
                                    labels=scaleFUN, limits=c(min,max))
}

df <- data.frame(prob_exceedance, exceed_scenario11, exceed_scenario18,
                 exceed_scenario15, exceed_scenario14, exceed_scenario16,
                 exceed_scenario13); 
colnames(df) <- c('Date', 'Scenario11', 'Scenario18', 'Scenario15', 'Scenario14',
                  'Scenario16', 'Scenario13')

options(scipen=5, width = 1400, height = 950)
myplot <- ggplot(df, aes(x=Date)) + 
  geom_line(aes(y=Scenario11, color=cn11), size=0.5) +
  geom_line(aes(y=Scenario18, color=cn18), size=0.5)+
  geom_line(aes(y=Scenario15, color=cn15), size=0.5)+
  geom_line(aes(y=Scenario14, color=cn14), size=0.5)+
  geom_line(aes(y=Scenario16, color=cn16), size=0.5)+
  geom_line(aes(y=Scenario13, color=cn13), size=0.5)+
  fixtheyscale+ 
  theme_bw()+ 
  theme(legend.position="top", 
        legend.title=element_blank(),
        legend.box = "horizontal", 
        legend.background = element_rect(fill="white",
                                         size=0.5, linetype="solid", 
                                         colour ="white"),
        legend.text=element_text(size=12),
        axis.text=element_text(size=12, colour="black"),
        axis.title=element_text(size=14, colour="black"),
        axis.line = element_line(colour = "black", 
                                 size = 0.5, linetype = "solid"),
        axis.ticks = element_line(colour="black"),
        panel.grid.major=element_line(colour = "light grey"), 
        panel.grid.minor=element_blank())+
  scale_colour_manual(values=c("black","purple", 'red', 'green', 'blue', 'orange'))+
  guides(colour = guide_legend(override.aes = list(size=5)))+
  labs(x= "Probability of Exceedance (%)", y = "Flow (cfs)")
ggsave(paste0(riv.seg, "_flow_exceedance_comp.png"), plot = myplot, device = 'png', width = 8, height = 5.5, units = 'in')
print(paste('Flow Exceedance plot saved at location ', as.character(getwd()), '/', riv.seg, '_flow_exceedance_comp.png', sep = ''))