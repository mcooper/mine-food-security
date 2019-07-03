setwd("G://My Drive/mine-food-security")

library(tidyverse)

loc <- read_csv('Abstract_locations_classified.csv') %>%
  select(EID, con_verdict, cty_verdict)
validation <- read_csv('Sample_Validation_Locations.csv') %>%
  select(EID, Continent, Country)

comb <- merge(validation, loc, all.x=T, all.y=F)

##Continent Validation

con <- comb %>%
  select(con_verdict, Continent) %>%
  filter(con_verdict %in% c("Africa", "Asia", "First World", "LAC")) %>%
  table

sum(diag(con))/sum(con)
#[1] 0.969697


##Country validation

cty <- comb %>%
  select(cty_verdict, Country) %>%
  filter(!is.na(cty_verdict)) %>%
  mutate(same=cty_verdict==Country)

sum(cty$same, na.rm=T)/nrow(cty)
#[1] 0.9326923