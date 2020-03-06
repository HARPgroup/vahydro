
# Load necessary libraries
library('zoo')
library('IHA')
library('stringr')
library('lubridate')


P_est <- function(b0, b1, x) {
  1/(1+exp(-(b0 + b1*x)));
}

b0 <- 1.93619;
b1 <- -0.0363938;
Qmin <- 0
Qmax <- 200
par(mfrow=c(2,2))
curve(P_est(b0, b1, x), Qmin, Qmax, ylim=c(0,1.00));
