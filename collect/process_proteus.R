#Based on data scraped from Proteus Index dashboard
#https://dataviz.vam.wfp.org/global-coverage-proteus-food-security-index-oct-2019

library(tidyverse)
library(countrycode)

setwd('G://My Drive/mine-food-security/Proteus Index')

fs <- list.files()

alldat <- data.frame()
for (f in fs){
  dat <- read.csv(f)
  names(dat)[1] <- 'Country'
  
  dat <- dat %>%
    select(Country, Proteus.index) %>%
    mutate(Year = as.numeric(substr(f, 25, 28)))
  
  alldat <- bind_rows(alldat, dat)
}

alldat$iso2c <- countrycode(alldat$Country, 'country.name', 'iso2c')

write.csv(alldat, '../ProteuxIndex.csv', row.names=F)
