library("rgl")
library("hydrotools")
basepath = "/var/www/R"
source("/var/www/R/config.R")
# Difficult Run
pid = 6569128
# element id from model
# - Difficult Run, 352131, 58.24 sqmi
elid = 352131 # 352006  240537
invar = "local_channel_Qin"
svar = "local_channel_last_S"
outvar = "local_channel_Qout"
# - Mountain Run above Lake Pelham, 352006, 26.15 sqmi
elid = 352006 # 352006  240537
invar = "local_channel_Qin"
svar = "local_channel_last_S"
outvar = "local_channel_Qout"
# - NF Shenandoah at Brock's Gap (Coote's Store), 240537 (river), 240541 (channel), 209.87 sqmi
invar = "Qin"
svar = "last_S"
outvar = "Qout"
elid = 240541 # 352006  240537
runid = 400
dt = 86400

dat <- om_get_rundata(elid, runid, site = omsite)

# form Qout = k * Qin^a * S^b
# logified as: log(Qout) = k + a * log(Qin) + b * log(S)
# employ lm() to help 
q_model5 <- lm( log(dat$Qout) ~ log(dat[,invar]) + log(dat[,svar]) )
summary(q_model5)
k <- coef(q_model5)[1]
a <- coef(q_model5)[2]
b <- coef(q_model5)[3]
Qout <- exp(k) * dat[,invar]^a * dat[,svar]^b
low_indices <- dat$Qout < 10.0
plot(Qout ~ dat$Qout)
plot(Qout[low_indices] ~ dat[low_indices,]$Qout)

plot3d(
  x=dat[,svar], y=dat[,outvar], z=dat[,invar],
  type = 's',
  xlab="S(t-1)", ylab="Qout", zlab="Qin"
)

plot3d(
  x=dat[,svar], y=Qout, z=dat[,invar],
  type = 's',
  xlab="S(t-1)", ylab="Qout", zlab="Qin"
)