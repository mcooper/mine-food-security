setwd('G://My Drive/mine-food-security')

library(tidyverse)
library(rgdal)
library(sp)
library(countrycode)
library(readxl)

options(stringsAsFactors=F)

sp <- readOGR('G://My Drive/DHS Spatial Covars/Global Codes and Shapefile', 'ne_50m_admin_0_countries')

sp$iso3 <- countrycode(sp$SOVEREIGNT, 'country.name', 'iso3c')

#Manually fix Kosovo and Kashmir
sp$iso3[sp$SOVEREIGNT=='Kashmir'] <- "IND"
sp$iso3[sp$SOVEREIGNT=='Kosovo'] <- "KOS"


dat <- read_xlsx('all_locations_processed_manual2.xlsx')

dat$iso3 <- countrycode(dat$country, 'country.name', 'iso3c')

dat$iso3[dat$country == 'Eswatini'] <- 'SWZ'
dat$iso3[dat$country == 'Kosovo'] <- "KOS"

###Merge
sp_sel <- sp@data %>%
  select(iso3, REGION_UN) %>%
  unique %>%
  filter(REGION_UN != 'Seven seas (open ocean)') %>%
  mutate(REGION_UN = replace(REGION_UN, duplicated(iso3) | duplicated(iso3, fromLast=TRUE), 'Europe'),
         REGION_UN = replace(REGION_UN, REGION_UN=="Europe", "First World"),
         REGION_UN = replace(REGION_UN, iso3 %in% c("USA", "AUS", "CAN", "NZL"), "First World"),
         REGION_UN = replace(REGION_UN, REGION_UN=="Oceania", "Asia"),
         REGION_UN = replace(REGION_UN, REGION_UN=="Americas", "LAC")) %>%
  unique %>%
  select(iso3, UN_Continent=REGION_UN)

new_sp <- merge(sp, sp_sel)
# 
# library(ggplot2)
# 
# new_sp@data$id <- rownames(new_sp@data)
# spf <- fortify(new_sp, region='id')
# spf$rownum <- 1:nrow(spf)
# 
# spf2 <- merge(spf, new_sp@data[ , c('id', 'UN_Continent')], all.x=T, all.y=F) %>%
#   arrange(rownum)
# 
# ggplot(spf2) + 
#   geom_polygon(aes(x=long, y=lat, group=group, fill=UN_Continent))

new_dat <- merge(dat, sp_sel, all.x=T, all.y=F)

new_dat$continent[is.na(new_dat$continent)] <- new_dat$UN_Continent[is.na(new_dat$continent)]

new_dat <- new_dat %>%
  select(iso3, location, latitude, longitude, country, continent, type=location_types_simple)

write.csv(new_dat, 'G://My Drive/mine-food-security/all_locations_processed_manual2_continents.csv', row.names=F)

new_sp <- new_sp[new_sp$UN_Continent != 'Antarctica', ]
