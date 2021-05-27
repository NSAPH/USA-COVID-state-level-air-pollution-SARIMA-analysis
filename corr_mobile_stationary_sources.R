rm(list=ls())

`%notin%` <- Negate(`%in%`)

nei <- read.csv('NEI_sector_report.txt')

## select only NO2 and PM2.5
neif <- nei %>% select(c('STATE','MAJOR_SOURCE_TYPE','EMISSION_TONS','POLLUTANT')) %>%
  filter(POLLUTANT %in% c('PM2.5')) %>%
  filter(STATE %notin% c('Puerto Rico', 'Virgin Islands','Tribal Land','District Of Columbia'))

nei_pm25_grp_source_perc <- neif %>% group_by(STATE, MAJOR_SOURCE_TYPE) %>%
  summarise(tot_emission = sum(EMISSION_TONS)) %>% arrange(STATE,tot_emission) %>%
  mutate(emission_perc = 100*tot_emission/sum(tot_emission)) %>%
  select(-tot_emission)%>%
  spread(MAJOR_SOURCE_TYPE, emission_perc) 

cor(nei_pm25_grp_source_perc$`Mobile Sources`, nei_pm25_grp_source_perc$`Stationary Sources`)
