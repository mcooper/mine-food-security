setwd('G://My Drive/mine-food-security')

library(tidyverse)
library(readxl)
library(rjson)
library(ggplot2)
library(countrycode)
library(sf)
library(viridis)
library(ape)
library(ggrepel)
library(pals)
library(Hmisc)
library(cowplot)
library(rgdal)
library(rnaturalearth)

options(stringsAsFactors=F)

#################################
#Read in and combine all data
#################################
pubs <- merge(read.csv('Abstract_locations_classified.csv') %>% 
                select(EID, cty_verdict),
              read.csv('abstracts_final.csv') %>% 
                select(EID, Year)) %>%
  filter(cty_verdict != '') %>%
  mutate(iso3c = case_when(cty_verdict == 'Eswatini' ~ 'SWZ',
                           cty_verdict == 'Kosovo' ~ 'UNK',
                           grepl('ncipe', cty_verdict) ~ 'STP',
                           TRUE ~ countrycode(cty_verdict, 'country.name', 'iso3c'))) %>%
  group_by(iso3c, Year) %>%
  summarise(pubs=n()) %>%
  ungroup %>%
  select(iso3c, year=Year, pubs)

pop <- read.csv('API_SP.POP.TOTL_DS2_en_csv_v2_936048.csv', skip=4) %>%
  select(Country.Code, matches('X....')) %>%
  gather(year, pop, -Country.Code) %>%
  mutate(year=as.numeric(substr(year, 2, 5)),
         iso3c=case_when(Country.Code == 'SOM' ~ 'SOM',
                         Country.Code == 'XKX' ~ 'UNK',
                         TRUE ~ countrycode(Country.Code, 'wb', 'iso3c'))) %>%
  filter(!is.na(iso3c)) %>%
  select(iso3c, year, pop) %>%
  arrange(iso3c, year) %>%
  group_by(iso3c) %>%
  mutate(pop=zoo::na.fill(pop, c('extend')))

proteus <- read_xlsx('WFP_Proteus_1990-2017.xlsx') %>%
  select(iso3c=iso, year, proteus=Proteus)

#spatial data, dealing with shared countries
cty <- ne_countries(returnclass='sf') %>%
  mutate(iso_a3 = case_when(iso_a3=='TWN' ~ 'CHN',
                            iso_a3=='ESH' ~ 'MAR',
                            iso_a3=='ATF' ~ 'FRA',
                            sovereignt=="Northern Cyprus" ~ 'CYP',
                            sovereignt=="Kosovo" ~ "UNK",
                            sovereignt=="Somaliland" ~ 'SOM',
                            TRUE ~ iso_a3))%>%
  rename(iso3c=iso_a3) %>%
  group_by(iso3c) %>%
  summarise()

pts <- read_xlsx('all_locations_processed_manual2.xlsx') %>%
  select(location, latitude, longitude) %>%
  mutate(latitude=ifelse(is.na(latitude), 0, latitude),
         longitude=ifelse(is.na(longitude), 0, longitude)) %>%
  st_as_sf(coords=c('longitude', 'latitude'), crs=4326) %>%
  st_join(cty) %>%
  filter(!is.na(iso3c)) %>%
  merge(read_csv('Abstract_locations_classified.csv') %>%
          select(EID, loc_abstract, loc_keywords, loc_title) %>%
          group_by(EID) %>%
          #Make unique row for each place
          expand(location = c(names(fromJSON(loc_abstract)),
                              names(fromJSON(loc_keywords)),
                              names(fromJSON(loc_title)))) %>%
          #Get the year
          merge(read.csv('abstracts_final.csv') %>% 
                  select(EID, year=Year)))

#get country-year counts of mentions
locs <- pts %>%
  st_drop_geometry() %>%
  group_by(iso3c, year) %>%
  summarise(locs=n())

Eswatini
Micronesia
Japan

#Get number of undernourished people
sdg <- read_xlsx('SDG 2.1.1.xlsx') %>%
  mutate(iso3c = case_when(GeoAreaName=='Eswatini' ~ 'SWZ',
                           TRUE ~ countrycode(GeoAreaName, 'country.name', 'iso3c')),
         pop_under = as.numeric(gsub('<', '', Value))) %>%
  select(year=TimePeriod, iso3c, pop_under)

comb <- Reduce(function(x, y){merge(x, y, all.x=T, all.y=T)},
               list(pubs, pop, proteus, locs, sdg)) %>%
  mutate(pubs = ifelse(is.na(pubs), 0, pubs),
         pubs_per_mil = pubs/(pop/1000000),
         pubs_per_und = pubs/pop_under)

cutseq <- c(1959, 1985, 1995, 2005, 2012, 2019)

comb5yrs <- comb %>%
  mutate(bidecade = cut(year, cutseq)) %>%
  group_by(iso3c, bidecade) %>%
  summarise(pubs=sum(pubs),
            pop=mean(pop),
            proteus=mean(proteus, na.rm=T),
            pubs_per_mil=mean(pubs_per_mil, na.rm=T),
            pubs_per_und=mean(pubs_per_und, na.rm=T))

pts5yrs <- pts %>%
  mutate(bidecade = cut(year, cutseq))

#################################
#Look at proteus vs pubs_per_mil
##################################

mapdat <- cty %>%
  merge(comb5yrs)

newmatdat <- cty %>%
  merge(comb %>% 
          filter(year > 2012) %>%
          group_by(iso3c) %>% 
          summarise(pubs_per_mil=mean(pubs_per_mil, na.rm=T),
                    pubs_per_und=mean(pubs_per_und, na.rm=T))) %>%
  filter(!is.na(pubs_per_mil))

newmatdatproj <- newmatdat %>%
  st_transform(crs = CRS('+proj=tpeqd +lat_1=0 +lon_1=0 +lat_2=45.56 +lon_2=90.56')) %>%
  st_centroid()

dm <- as.matrix(dist(newmatdatproj %>% st_coordinates))

dm.inv <- 1/dm
diag(dm.inv) <- 0

Moran.I(newmatdatproj$pubs_per_und, dm.inv, na.rm=T)$p.value


ggplot() + 
  geom_sf(data=newmatdat, aes(fill=pubs_per_und)) + 
  scale_fill_viridis()


formatlabs <- function(str){
    start <- substr(str, 2, 5)
    end <- substr(str, 7, 10)
    paste0(as.numeric(start) + 1, '-', end)
}

levels(mapdat$bidecade) <- formatlabs(levels(mapdat$bidecade))
levels(pts5yrs$bidecade) <- formatlabs(levels(pts5yrs$bidecade))

pts5yrs$lab <- ''


newmatdat$pubs_per_mil[newmatdat$pubs_per_mil > 0.25] <- 0.25

ggplot() + 
  geom_sf(data=newmatdat, aes(fill=pubs_per_mil))

ggplot() + 
  geom_sf(data = mapdat, aes(fill=pubs_per_und), 
          color='transparent') + 
  geom_sf(data = pts5yrs, aes(color=lab), size=0.25, linetype=18) + 
  scale_fill_viridis() + 
  scale_color_manual(values="#000000") +
  facet_wrap(bidecade ~ ., nrow=2) + 
  theme_void() + 
  theme(legend.position=c(0.8, 0.2),
        legend.direction = 'horizontal',
        legend.box = 'vertical') + 
  guides(fill = guide_legend(title.position="top", title.hjust = 0.5))

ggplot() + 
  geom_sf(data = mapdat, aes(fill=log(locs_per_mil*10+1)), 
          color='transparent') + 
  #geom_sf(data = pts5yrs) + 
  scale_fill_viridis() + 
  facet_wrap(bidecade ~ ., nrow=2) + 
  theme_void()

for (i in levels(mapdat$bidecade)){
  print(i)
  
  sel <- mapdat %>% 
    filter(bidecade == i, !is.na(pubs_per_mil)) %>%
    st_transform(crs = CRS('+proj=tpeqd +lat_1=0 +lon_1=0 +lat_2=45.56 +lon_2=90.56')) %>%
    st_centroid()
  
  with(sel %>% 
         na.omit, 
       cor(proteus, log(locs_per_mil + 1))) %>%
    print
  
  dm <- as.matrix(dist(sel %>% st_coordinates))
  
  dm.inv <- 1/dm
  diag(dm.inv) <- 0
  
  print(Moran.I(log(sel$locs_per_mil + 1), dm.inv)$p.value)
  
}



ggplot(comb5yrs %>%
         filter(bidecade=='(2012,2017]')) +
  geom_text_repel(aes(x=proteus, y=log(pubs_per_mil + 1), label=iso3c), segment.alpha=0) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0), labels = function(x){round(exp(x), 1)}) +
  theme_bw() +
  xlab('Global Food Security Index') +
  ylab('Articles Per Million People')

ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Graph.eps', width=10, height=6)







comb$mentions_c <- cut2(comb$Mentions_Per_Cap_Log, g=3)
comb$mentions_q <- as.numeric(comb$mentions_c)
comb$Objective_c <- cut2(comb$Objective, g=3)
comb$Objective_q <- as.numeric(comb$Objective_c)




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
  theme(legend.position="bottom",
        legend.key = element_blank(),
        axis.title = element_text(size = 10),
        legend.title = element_text(size = 10)) + 
  scale_x_continuous(expand=c(0,0), breaks=NULL,
                     sec.axis = dup_axis(name="Global Food Security Index", breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(24, 51, 70, 86))) + 
  scale_y_continuous(expand=c(0,0), breaks = NULL,
                     sec.axis = dup_axis(name="Articles Per Million People", breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(0, 0.6, 1.9, 20))) + 
  coord_fixed()
legend

ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +
  draw_plot(legend, -0.175, 0.025, 0.575, 0.575)

ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Map.png', width=10, height=5)
#Note: because ggsave() cant handle the unicode in the legend with EPS, must run:

#convert Bivariate_Map.png Bivariate_Map.eps


















