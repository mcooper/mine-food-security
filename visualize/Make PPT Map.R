library(rnaturalearth)
library(sf)
library(tidyverse)

cty <- ne_countries(returnclass='sf') %>%
  filter(sovereignt %in% c('Ethiopia', 'United Republic of Tanzania',
                           'Kenya', 'Uganda'))

df <- data.frame(x=c(38.948965, 35.009952, 31.353693, 38.296795),
                 y=c(4.754699, -0.199430, 1.432365, -4.805637)) %>%
  st_as_sf(coords=c('x', 'y'), crs=4326)

ggplot() + 
  geom_sf(data=cty) + 
  geom_sf(data=df, pch=16, size=3, color=rgb(56/255, 87/255, 35/255)) + 
  theme_void()

ggsave('G://My Drive/mine-food-security/graphic_fig.png')
