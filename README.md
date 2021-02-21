# USA-COVID-state-level-air-pollution-SARIMA-analysis

This repository contains the code used for analysis in our work on the short term air pollution changes in the USA. The preprint can be found [here](https://www.medrxiv.org/content/10.1101/2020.08.04.20168237v2.full.pdf).

The code uses bootstrapped seasonal autoregressive time series models to make counterfactual predictions for pollutant concentrations based on historical data. These predictions are compared to the the actual pollutant concentrations to estimate the corresponding change during the pandemic.

## File description:

1. *confounders_all.csv* contains the temperature, precipitation and relative humidity values for each state as a function of time. 

2. *data_alltimeno2.csv*  contains the measured NO2 concentrations for each state as a function of time.

3. *data_alltimepm25.zip*  contains the measured PM2.5 concentrations for each state as a function of time.  

4. *df_regions.csv*  contains the region designations for each state. 

5. *pop_density_census2010.csv* contains the population density (per square mile) of each state based on the 2010 census. 

6. *state_policy_changes_1.csv* contains the dates of different covid-related interventions for each state.

7. *df_change_pm25.csv* and *df_change_no2.csv* are obtained as outputs of the SARIMA analysis performed using the codes *Rcode_PM25_figure1.R*  and *Rcode_NO2_figure1.R* respectively. These files contain the estimated change in pollutant concentrations following the state of emergency declaration in each state, based on our analysis.

## How to run the code:

The code should be run in the following order:

For NO2,<br />
<br />
Step 1. run *Rcode_NO2_figure1.R* (you can reduce the number of bootstraps to 10 to save hours of run time).<br />
Step 2. save the dataframe *df_change_no2* that is generated in this code as *df_change_no2.csv*. (you can also use *df_change_no2.csv* file that is in this repo).<br />

For PM2.5,<br />
<br />
Step 3. run *Rcode_PM25_figure1.R* (you can reduce the number of bootstraps, *num_resamples = 10* to save hours of run time, currently it is set to 1000).<br />
Step 4. save the dataframe *df_change* that is generated in this code as *df_change_pm25.csv*. (you can also use *df_change_pm25.csv* file that is in this repo).<br />

Finally regression,<br />
<br />
Step 5. run the regression analysis *Rcode_regression_NEI_WLS.R*<br />
Note: This code performs regression analysis for both NO2 and PM2.5. If you wish to only run the code for one pollutant, you will need to comment out the analysis of the other pollutant to avoid getting an error.<br />
