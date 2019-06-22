setwd('G://My Drive/mine-food-security')

library(tidyverse)
library(rgdal)
library(sp)
library(ggplot2)
library(viridis)
library(countrycode)

loc <- read_csv('Abstract_locations_classified.csv') %>%
  filter(!is.na(cty_verdict)) %>%
  group_by(cty_verdict) %>%
  summarize(count=n()) %>%
  mutate(iso3c=countrycode(cty_verdict, 'country.name', 'iso3c'),
         iso3c=replace(iso3c, cty_verdict=='Eswatini', 'SWZ'),
         iso3c=replace(iso3c, cty_verdict=='Kosovo', 'KOS'),
         iso3c=replace(iso3c, is.na(iso3c), 'STP'))

sp <- readOGR('G://My Drive/DHS Spatial Covars/Global Codes and Shapefile', 'ne_50m_admin_0_countries')
sp <- sp[ , c('SOVEREIGNT', 'POP_EST')]

sp$iso3c <- countrycode(sp$SOVEREIGNT, 'country.name', 'iso3c')

#Manually fix Kosovo and Kashmir
sp$iso3c[sp$SOVEREIGNT=='Kashmir'] <- "IND"
sp$iso3c[sp$SOVEREIGNT=='Kosovo'] <- "KOS"

spdat <- sp@data %>%
  group_by(iso3c) %>%
  summarize(pop=sum(POP_EST, na.rm=T))

spdat <- merge(spdat, loc)

sp <- sp::merge(sp, spdat)


lat_long <- read_csv('all_locations_processed_manual2_continents.csv') %>%
  filter(!is.na(longitude))

points <- SpatialPointsDataFrame(lat_long[ , c('longitude', 'latitude')], data=lat_long, proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

points <- spTransform(points, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
sp <- spTransform(sp, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))

points@data[ , c('x', 'y')] <- points@coords

points@data$lab <- ""

#Make blank Robinson Background
rob <- c(seq(-180, 180, 1), rep(180, 180), seq(180, -180, -1), rep(-180, 180),
         rep(-90, 360),     seq(-90, 90, 1), rep(90, 360), seq(90, -90, -1)) %>%
  matrix(ncol=2) %>%
  Polygon %>%
  list %>%
  Polygons(1) %>%
  list %>%
  SpatialPolygons(proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")) %>%
  spTransform(CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))


#Make Visualization
sp <- sp[sp$POP_EST > 1000, ]

sp@data$id <- rownames(sp@data)
sp$Mentions_Per_Cap <- (sp$count + 1)/(sp$pop/1000000)
sp$Mentions_Per_Cap[sp$count == 0] <- 0

sp$Mentions_Per_Cap[is.na(sp$Mentions_Per_Cap)] <- 0
sp$Mentions_Per_Cap[sp$Mentions_Per_Cap > 20] <- 20

write.csv(sp@data %>% select(iso3c, Mentions_Per_Cap, pop) %>% unique, 'Mentions_Per_Cap.csv', row.names=F)

spf <- fortify(sp, region='id')
spf$rownum <- 1:nrow(spf)

spf2 <- merge(spf, sp@data, all.x=T, all.y=F) %>%
  arrange(rownum)

robf <- fortify(rob)

my_breaks <- round(exp(seq(log(0.1), log(max(sp$Mentions_Per_Cap)), length.out=4)), 1)

ggplot() + 
  geom_polygon(data=robf,  aes(x=long, y=lat, group=group), fill='#CCCCCC') + 
  geom_polygon(data=spf2, aes(x=long, y=lat, group=group, fill=Mentions_Per_Cap)) + 
  geom_point(data=points@data, aes(x=x, y=y, color=lab), size=0.25, shape=3) + 
  scale_fill_viridis(option='D', trans='log', breaks = my_breaks, labels = my_breaks, 
                     na.value="#440154") + 
  theme_void()+
  labs(fill="Food Security Abstracts Per Million People") + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position="bottom", 
        legend.box = "vertical") +
  scale_color_manual(values = "#000000", name='Toponyms in Abstracts') + 
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))

ggsave('C://Users/matt/mine-food-security-tex/img/Mentions_Map2.png', width=12, height=6)


