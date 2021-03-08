rm(list=ls())

set.seed(123)

`%notin%` <- Negate(`%in%`)

library(readxl)
library(tidyverse)
library(ggplot2)
library(boot)
library(ggthemes)
library(gridExtra)
library(forecast)
library(data.table)

dfpoll_orig <- read.csv('data_alltimeno2.csv')
dfpoll_orig$date <- as.Date(dfpoll_orig$date)

state_policy<- read.csv('state_policy_changes_1.csv')
state_policy <- state_policy %>% filter(State %notin% c('District of Columbia', 'Total with each policy (out of 51 with DC)'))

confounders_daily <- read.csv('confounders_all.csv')
confounders_daily$date <- as.Date(confounders_daily$date)

#################################################
## Select data before April 29, 2020 (inclusive)
## for all datasets
#################################################

maxdate ='2020-04-29'

#################################################
## INPUT PARAMETERS
#################################################


## train data
ldate <- as.Date("2020-01-01")
nweekspred = 16 # # of weeks to predict on
udate <- (ldate+7*nweekspred) # date to predict until


#################################################
## RUN THE LOOP
#################################################

dfs_tosave = list()
p = list()
i=1
acc_avg=list()
states =list()
train_forecast_avg= list()
train_forecast_sd=list()

for (state_fullname in unique(state_policy$State[1:5])){
  if (state_fullname=='Alaska'){next}
  
  #################################################
  ## DATA WRANGLING
  #################################################
  
  # get abbreviated name
  state_name = state.abb[which(state.name == state_fullname)]
  
  if (state_name %notin% unique(dfpoll_orig$state)) {next}
  
  
  # get date of state of emergency
  soe= as.Date(state_policy$State.of.emergency[state_policy$State == state_fullname], format= '%m/%d/%Y')
  
  
  dfpoll <- dfpoll_orig %>% filter (state==state_name) %>% group_by(date) %>% summarise(no2 = mean(no2))
  
  dfpoll<-dfpoll %>%
    complete(date = seq.Date(min(date), max(date), by="day")) %>%
    fill('no2') %>% filter( date < as.Date(maxdate))
  
  cat("State = ", state_fullname,"  ")
  
  if (nrow(dfpoll)<1940) {print("next ")
    next}
  

  
  conf_state <- confounders_daily %>% filter(stateabbr == state_name)%>% filter( date < as.Date(maxdate)) %>%
    complete(date = seq.Date(min(date), max(date), by="day")) %>%
    fill('tmmx','pr','rmax')
  
  
  n=7 ## average every seven rows
  m = (nrow(dfpoll)%/%n)*n
  
  
  ## take avg every n days. This will reduce the length of
  # the time series by a factor of n
  dfweek <- setDT(dfpoll[1:m,])[,.(no2=mean(no2)), date-0:(n-1)]
  dfweek$idx <- seq(1, nrow(dfweek))
  
  
  ## take avg every n days for confounders. 
  temp_week <- setDT(conf_state[1:m,])[,.(temp = mean(tmmx)), date-0:(n-1)]
  ppt_week <- setDT(conf_state[1:m,])[,.(ppt = mean(pr)), date-0:(n-1)]
  hum_week <- setDT(conf_state[1:m,])[,.(hum = mean(rmax)), date-0:(n-1)]
  
  xregs <- cbind(temp_week, ppt_week$ppt, hum_week$hum)
  colnames(xregs) <- c('date','temp','ppt','hum')
  
  train = dfweek %>% filter(date<ldate) # ldate not included
  train$idx <- seq(1, nrow(train))
  
  xregs_train <- xregs %>% filter(date<ldate) # ldate not included
  xregs_train <- xregs_train[,.(temp,ppt,hum)]
  
  xregs_train <- as.matrix(xregs_train)
  
  ## test data from poll
  test = dfweek %>%  filter(date>=ldate & date <udate)## include ldate and filter(date>=ldate & date <udate)
  
  
  
  ## test data for confounders
  xregs_test <- xregs %>%  filter(date>=ldate & date <udate)
  xregs_test <- xregs_test[i,.(temp,ppt,hum)]
  xregs_test <- as.matrix(xregs_test)
  
  
  ts=ts(train$no2)
  
#  num_resamples=1000
  num_resamples=10 # lower for testing

  sim <- bld.mbb.bootstrap(ts, num_resamples)
  preds = matrix(list(), nrow=num_resamples)
  
  acc= list()
  train_forecast = list()
  
  for (j in seq(1, length(sim))) {
    
    model = auto.arima(sim[[j]], xreg = as.matrix(xregs_train), seasonal = TRUE)
    forecast = forecast(model,h = nweekspred, xreg = xregs_test,level = 0.95)
    train_forecast[[j]] = forecast(model,xreg = xregs_train,level = 0.95)$mean
    
    preds[[j]] = forecast$mean
    
    acc[[j]] = forecast::accuracy(model)
    
  }
  acc <-as.data.frame(lapply(acc,as.numeric ))
  acc_avg[[i]] <- rowMeans(acc)
  
  train_forecast <-as.data.frame(lapply(train_forecast,as.numeric ))
  train_forecast_avg[[i]] <- rowMeans(train_forecast)
  train_forecast_sd[[i]] <- (apply(train_forecast,1,sd))
  
  states[[i]] <- state_name
  
  i = i+1
}

acc_avg <- data.frame(acc_avg)

k=6 #for MASE
MASE <- acc_avg[k,]


names(MASE) <- unlist(states)
MASE <- data.frame(as.numeric(MASE))
names(MASE) <- 'mase'


mase_no2_plot <- ggplot(MASE) + geom_histogram(aes(x=mase), bins = 10) + 
  theme_classic() + xlab('MASE') + ylab ('Number of states')+
  theme(
    axis.text.x=element_text(size=16),
    axis.text.y=element_text(size=16),
    axis.title.x=element_text(angle=0, color='black', size=16),
    axis.title.y=element_text(angle=90, color='black', size=16)
  )+xlim(0.69, 1.01)

png("figures/mase_no2_plot.png", height=1000, width=2000)
print(mase_no2_plot)
dev.off()

