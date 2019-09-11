setwd('G://My Drive/mine-food-security')

library(tidyverse)
library(ggplot2)
library(countrycode)
library(ggrepel)
library(pals)
library(Hmisc)
library(cowplot)
library(rgdal)

dat <- read.csv('Mentions_Per_Cap.csv')

gfsi <- read.csv('Objective Metrics/EIU Global Food Security Index/GFSI.csv') %>%
  mutate(iso3c = countrycode(Country, 'country.name', 'iso3c'),
         iso2c = countrycode(Country, 'country.name', 'iso2c')) %>%
  rename(Objective = GFSI)

voth <- read.csv('Objective Metrics/FAO Voices of the Hungry/VotH_clean.csv') %>%
  mutate(iso3c = countrycode(Country, 'country.name', 'iso3c'),
         iso2c = countrycode(Country, 'country.name', 'iso2c'),
         Objective = 100 - Mod_Prev)

voth$iso3c[voth$Country == 'Kosovo'] <- "KOS"

comb <- merge(gfsi, dat, all.x=T, all.y=F)

comb$Mentions_Per_Cap_Log <- log(comb$Mentions_Per_Cap)

sel <- comb %>%
  select(Objective, Mentions_Per_Cap, Mentions_Per_Cap_Log) %>%
  na.omit %>%
  filter(!is.infinite(Mentions_Per_Cap_Log))

cor(sel$Mentions_Per_Cap_Log, sel$Objective)

ggplot(comb) +
  geom_text_repel(aes(x=Objective, y=log(Mentions_Per_Cap), label=iso2c), segment.alpha=0) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0), labels = function(x){round(exp(x), 1)}) +
  theme_bw() +
  xlab('Global Food Security Index') +
  ylab('Articles Per Million People')

ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Graph.png', width=10, height=6)


comb$mentions_q <- as.numeric(cut2(comb$Mentions_Per_Cap_Log, g=3))
comb$Objective_q <- as.numeric(cut2(comb$Objective, g=3))

#Get a bivariate palette
#There are a lot of options, see here: https://rdrr.io/cran/pals/man/bivariate.html

sp <- readOGR('G://My Drive/DHS Spatial Covars/Global Codes and Shapefile', 'ne_50m_admin_0_countries')
sp <- sp[ , c('SOVEREIGNT')]
sp <- spTransform(sp, CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))

sp$iso3c <- countrycode(sp$SOVEREIGNT, 'country.name', 'iso3c')

#Manually fix Kosovo and Kashmir
sp$iso3c[sp$SOVEREIGNT=='Kashmir'] <- "IND"
sp$iso3c[sp$SOVEREIGNT=='Kosovo'] <- "KOS"

pal_ix <- apply(t(matrix(1:9, nrow=3)), 2, rev)

comb$color <- mapply(FUN=function(x, y){pal_ix[x, y]}, x=comb$mentions_q, y=comb$Objective_q) %>%
  as.factor

spnew <- merge(sp, comb)

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

spnew@data$id <- rownames(spnew@data)

spf <- fortify(spnew, region='id')
spf$rownum <- 1:nrow(spf)

spf2 <- merge(spf, spnew@data, all.x=T, all.y=F) %>%
  arrange(rownum)

robf <- fortify(rob)

palette <- stevens.pinkgreen()
palette[1] <- "#e3e3e3"
names(palette) <- 1:9

map <- ggplot() + 
  geom_polygon(data=robf,  aes(x=long, y=lat, group=group), fill='#FFFFFF') + 
  geom_polygon(data=spf2, aes(x=long, y=lat, group=group, fill=color), color='#FFFFFF',
               size=0.3) +
  scale_fill_manual(values = palette, na.value='#aaaaaa') + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) + 
  guides(fill=FALSE) + 
  theme_void()+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))
map

leg_dat <- comb %>%
  dplyr::select(mentions_q, Objective_q, color) %>%
  unique

legend <- ggplot() +
  geom_point(data = data.frame(x=1, y=1, color=factor(1)), aes(x=x, y=x, color=color), 
             size=10, shape=15) + 
  geom_tile(data = leg_dat, aes(x=Objective_q, y=mentions_q, fill=color),
            show.legend=FALSE) +
  scale_color_manual(values = c(`1`='#aaaaaa'), name="Missing GFSI Data", labels=NULL) + 
  scale_fill_manual(values = palette) +
  labs(x = sprintf("More Food Secure \u2192"),
       y = sprintf("More Researched \u2192")) +
  theme(axis.ticks.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.text.x=element_blank(),
        legend.position="bottom",
        legend.key = element_blank(),
        axis.title = element_text(size = 10),
        legend.title = element_text(size = 10)) + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0)) + 
  coord_fixed()
legend

ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +
  draw_plot(legend, -0.175, 0.025, 0.575, 0.575)

ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Map.png', width=10, height=5)



















