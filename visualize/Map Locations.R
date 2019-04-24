setwd('G://My Drive/mine-food-security')

library(tidyverse)
library(rgdal)
library(sp)
library(ggplot2)
library(viridis)

loc <- read_csv('All_Locations.csv')
lat_log <- read_csv('all_locations_processed_manual_onlygood.csv') %>%
  select(-count)

loc_ll <- merge(loc, lat_log, all.x=T, all.y=F) %>%
  filter(!is.na(latitude))

points <- SpatialPointsDataFrame(loc_ll[ , c('longitude', 'latitude')], data=loc_ll, proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

sp <- readOGR('G://My Drive/DHS Spatial Covars/Global Codes and Shapefile', 'ne_50m_admin_0_countries')
sp <- sp[ , c('ADMIN', 'POP_EST')]

points$ADMIN <- unlist(over(points, sp[ , 'ADMIN']))

summ <- points@data %>%
  group_by(ADMIN) %>%
  summarize(total=sum(count)) %>%
  na.omit

sp <- sp::merge(sp, summ)
sp@data$total[is.na(sp@data$total)] <- 0

points <- spTransform(points, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
sp <- spTransform(sp, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))

points@data[ , c('x', 'y')] <- points@coords

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
sp$Mentions_Per_Cap <- (sp$total + 1)/(sp$POP_EST/1000000)
sp$Mentions_Per_Cap[sp$total == 0] <- 0

write.csv(sp@data, 'Mentions_Per_Cap.csv', row.names=F)

spf <- fortify(sp, region='id')
spf$rownum <- 1:nrow(spf)

spf2 <- merge(spf, sp@data, all.x=T, all.y=F) %>%
  arrange(rownum)

robf <- fortify(rob)

sp$Mentions_Per_Cap[is.nan(sp$Mentions_Per_Cap)] <- 0

my_breaks <- round(exp(seq(0, log(max(sp$Mentions_Per_Cap)), length.out=5)))

my_breaks[5] <- my_breaks[5] - 1

ggplot() + 
  geom_polygon(data=rob,  aes(x=long, y=lat, group=group), fill='#CCCCCC') + 
  geom_polygon(data=spf2, aes(x=long, y=lat, group=group, fill=Mentions_Per_Cap)) + 
  geom_point(data=points@data, aes(x=x, y=y), color='#000000', size=0.25, shape=3) + 
  scale_fill_viridis(option='D', trans='log', breaks = my_breaks, labels = my_breaks, na.value="#440154") + 
  theme_void()+
  labs(fill="") + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))

ggsave('C://Git/mine-food-security-tex/img/Mentions_Map.png', width=12, height=5)


