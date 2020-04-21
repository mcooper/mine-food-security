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
library(sp)
library(xtable)

options(stringsAsFactors=F, scipen = 10)

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
                            iso_a3=='FLK' ~ 'GBR',
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

###########################################################
# Map mean publications per million per year with points
###########################################################

sp <- cty %>%
  merge(comb %>%
          group_by(iso3c) %>%
          summarise(pubs_per_mil_per_year = mean(pubs_per_mil)))
sp$pubs_per_mil_per_year[sp$pubs_per_mil_per_year > 0.4] <- 0.4

bckgd <- c(seq(-180, 180, 1), rep(180, 146), seq(180, -180, -1), rep(-180, 146),
           rep(-56, 360),     seq(-56, 90, 1), rep(90, 360), seq(90, -56, -1)) %>%
  matrix(ncol=2) %>%
  list %>%
  st_polygon %>%
  st_sfc
st_crs(bckgd) <- st_crs(sp)

my_breaks <- c(0.001, 0.01, 0.1, 0.4)
  
map <- ggplot() + 
  geom_point(data=data.frame(x=0, y=0, lab='a'), aes(x=x, y=y, color=lab), size=0.25, shape=18) + 
  geom_sf(data=bckgd, fill='#CCCCCC') + 
  geom_sf(data=sp, aes(fill=pubs_per_mil_per_year, alpha=pubs_per_mil_per_year < 0.001), color='#FFFFFF', size=0.3) + 
  geom_sf(data=pts, size=0.25, shape=18) + 
  scale_fill_viridis(option='D', trans='log',
                     na.value="#440154", guide = guide_colorbar(title.position = "top"),
                     labels=my_breaks, breaks=my_breaks) + 
  theme_void() +
  labs(fill="Food Security Abstracts Per Million People") + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position=c(0.145, 0.15),
        legend.box.background=element_rect(fill='#CCCCCC', color="#000000"),
        legend.box.margin=margin(t=4, r=4, b=4, l=4, unit='pt'),
        legend.direction='horizontal',
        legend.box='vertical'
  ) + 
  guides(colour = guide_legend(override.aes = list(size=2), title.position = 'top'), alpha=FALSE) +
  scale_color_manual(values = "#000000", labels=NULL, name='Toponyms in Abstracts') + 
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  scale_alpha_manual(values=c(1, 0.75)) + 
  coord_sf(crs=CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))

ggsave(plot = map, filename = 'C://Users/matt/mine-food-security-tex/img/Per_Cap_Map.pdf', width=10.5, height=4.5)

###########################################################
# Same thing, but over separate periods
###########################################################

cutseq <- c(1959, 1985, 1995, 2005, 2012, 2019)

comb5yrs <- comb %>%
  mutate(bidecade = cut(year, cutseq)) %>%
  group_by(iso3c, bidecade) %>%
  summarise(pubs=sum(pubs),
            pop=mean(pop),
            proteus=mean(proteus, na.rm=T),
            pubs_per_mil_per_year=mean(pubs_per_mil, na.rm=T),
            pubs_per_und=mean(pubs_per_und, na.rm=T))

pts5yrs <- pts %>%
  mutate(bidecade = cut(year, cutseq))

mapdat5yrs <- cty %>%
  merge(comb5yrs)


formatlabs <- function(str){
  start <- substr(str, 2, 5)
  end <- substr(str, 7, 10)
  end <- ifelse(end == '2019', '2018', end)
  paste0(as.numeric(start) + 1, '-', end)
}

levels(mapdat5yrs$bidecade) <- formatlabs(levels(mapdat5yrs$bidecade))
levels(pts5yrs$bidecade) <- formatlabs(levels(pts5yrs$bidecade))

my_breaks <- c(0.0001, 0.001, 0.01, 0.1, 1)

map2 <- ggplot() + 
  geom_point(data=data.frame(x=0, y=0, lab='a', bidecade=levels(mapdat5yrs$bidecade)), aes(x=x, y=y, color=lab), size=0.25, shape=18) + 
#  geom_sf(data=bckgd, fill='#CCCCCC') + 
  geom_sf(data=mapdat5yrs, aes(fill=pubs_per_mil_per_year, alpha=pubs_per_mil_per_year < 0.001), color='#FFFFFF', size=0.3) + 
  geom_sf(data=pts5yrs, size=0.25, shape=18) + 
  scale_fill_viridis(option='D', trans='log',
                     na.value="#440154", guide = guide_colorbar(title.position = "top"),
                     labels=my_breaks, breaks=my_breaks) + 
  theme_void() +
  labs(fill="Food Security Abstracts Per Million People") + 
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.position=c(0.75, 0.15)#,
        #legend.direction='horizontal',
        #legend.box='vertical'
  ) + 
  guides(colour = guide_legend(override.aes = list(size=2), title.position = 'top'), alpha=FALSE) +
  scale_color_manual(values = "#000000", labels=NULL, name='Toponyms in Abstracts') + 
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) + 
  scale_alpha_manual(values=c(1, 0.75)) + 
  coord_sf(crs=CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")) + 
  facet_wrap(. ~ bidecade, nrow = 3)

ggsave(plot=map2, filename = 'C://Users/matt/mine-food-security-tex/img/Per_Cap_Map2.pdf', width=10, height=8)

#############################################################
#Conduct Morans I tests on all data, and by year grouping
#############################################################

#Do all years
morandat <- sp %>%
  st_transform(crs = CRS('+proj=tpeqd +lat_1=0 +lon_1=0 +lat_2=45.56 +lon_2=90.56')) %>%
  st_centroid()

dm <- as.matrix(dist(morandat %>% st_coordinates))

dm.inv <- 1/dm
diag(dm.inv) <- 0

mi <- Moran.I(morandat$pubs_per_mil_per_year, dm.inv, na.rm=T) %>%
  data.frame %>%
  mutate(period='All Years')

#Now do it periodically
for (l in levels(mapdat5yrs$bidecade)){
  sel <- mapdat5yrs %>%
    filter(bidecade==l)
  
  morandat <- sel %>%
    st_transform(crs = CRS('+proj=tpeqd +lat_1=0 +lon_1=0 +lat_2=45.56 +lon_2=90.56')) %>%
    st_centroid()
  
  dm <- as.matrix(dist(morandat %>% st_coordinates))
  
  dm.inv <- 1/dm
  diag(dm.inv) <- 0
  
  mi <- bind_rows(Moran.I(morandat$pubs_per_mil_per_year, dm.inv, na.rm=T) %>%
                    data.frame %>%
                    mutate(period=l),
                  mi)
}

mitab <- xtable(mi %>% select(Period = period,
                              Observed = observed,
                              Expected = expected,
                              `Standard Deviation`=sd,
                              `P-Value`=p.value),
                digits=c(0, 0, 3, 3, 3, -2),
                caption='Results of Morans I Test, by year grouping and by all years',
                label='tab:moran', align=c('l', 'l', 'r', 'r', 'r', 'r'))

print(mitab, file='C://Users/matt/mine-food-security-tex/tables/mitab.tex',
      table.placement='H',
      include.rownames=F, include.colnames=T)

#########################################
# Save table of results for appendix
###########################################
sumtab <- comb %>%
  group_by(iso3c) %>%
  summarise(pubs_per_mil_per_year = mean(pubs_per_mil)) %>%
  select(iso3c, `All Years`=pubs_per_mil_per_year) %>%
  na.omit %>%
  merge(comb5yrs %>%
          mutate(bidecade = formatlabs(bidecade)) %>%
          select(iso3c, bidecade, pubs_per_mil_per_year) %>%
          spread(bidecade, pubs_per_mil_per_year)) %>%
  mutate(`Country` = case_when(iso3c=='UNK' ~ 'Kosovo',
                               TRUE ~ countrycode(iso3c, 'iso3c', 'country.name'))) %>%
  arrange(desc(`All Years`)) %>%
  select(Country, `ISO-3`=iso3c, `All Years`, `1960-1985`, 
         `1986-1995`, `1996-2005`, `2006-2012`, `2013-2018`)

st <- xtable(sumtab, digits=c(0, 0, 0, 4, 4, 4, 4, 4, 4),
       caption='Publications per Captia per Year',
       label='tab:ppcpy')

print(st, file='C://Users/matt/mine-food-security-tex/tables/sumtab.tex',
      table.placement='H',
      include.rownames=F, include.colnames=T,
      tabular.environment="longtable")

#################################
#Look at proteus vs pubs_per_mil
##################################

sp <- mapdat5yrs %>%
  filter(bidecade=='2013-2018')

sp$proteus_q <- cut2(sp$proteus, g=3)
sp$mentions_q <- cut2(sp$pubs_per_mil_per_year, g=3)

r <- function(x) t(apply(x, 2, rev))

pal_ix <- t(r(r(matrix(1:9, nrow=3))))

sp$color <- mapply(FUN=function(x, y){pal_ix[x, y]}, x=sp$mentions_q, y=sp$proteus_q) %>%
  as.factor

#Make Visualization
palette <- stevens.pinkgreen()
palette[1] <- "#e3e3e3"
names(palette) <- c(1, 2, 3, 4, 5, 6, 7, 8, 9)

map3 <- ggplot() + 
  geom_sf(data=sp, aes(fill=color), color='#FFFFFF',
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
  scale_y_continuous(expand = c(0, 0)) + 
  coord_sf(crs=CRS("+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
map3

leg_dat <- sp %>%
  na.omit %>%
  select(mentions_q, proteus_q, color) %>%
  mutate(mentions_q=as.numeric(mentions_q),
         proteus_q=as.numeric(proteus_q)) %>%
  st_drop_geometry %>%
  unique

names(palette) <- c(3, 2, 1, 6, 5, 4, 9, 8, 7)

legend <- ggplot() +
  geom_point(data = data.frame(x=1, y=1, color=factor(1)), aes(x=x, y=x, color=color), 
             size=10, shape=15) + 
  geom_tile(data = leg_dat, aes(x=proteus_q, y=mentions_q, fill=color),
            show.legend=FALSE) +
  scale_color_manual(values = c(`1`='#aaaaaa'), name="No Proteus Index Data", labels=NULL) + 
  scale_fill_manual(values = palette) +
  labs(x = sprintf("More Food Secure \u2192"),
       y = sprintf("More Researched \u2192")) +
  theme(legend.position="bottom",
        legend.key = element_blank(),
        axis.title = element_text(size = 10),
        legend.title = element_text(size = 10),
        plot.background = element_rect(fill='transparent',
                                       color='transparent')) + 
  scale_x_continuous(expand=c(0,0), breaks=NULL,
                     sec.axis = dup_axis(name="Proteus Index", breaks = c(0.5, 1.5, 2.5, 3.5), labels = rev(c(0.08, 0.28, 0.45, 0.79)))) + 
  scale_y_continuous(expand=c(0,0), breaks = NULL,
                     sec.axis = dup_axis(name="Articles Per Million People\nPer Year", breaks = c(0.5, 1.5, 2.5, 3.5), labels = c(0,0.05, 0.15, 5.65))) + 
  coord_fixed()

ggdraw() +
  draw_plot(map3, 0, 0, 1, 1) +
  draw_plot(legend, -0.165, 0, 0.575, 0.575)

ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Map.png', width=10, height=5)
#Note: because ggsave() cant handle the unicode in the legend with EPS, must run:
#convert Bivariate_Map.png Bivariate_Map.eps


############################################################################
# Point graph of places over time
################################################################################3



revlab <- function(x){
  round((exp(x) - 1)/100, 3)
}

sp <- sp %>%
  select(proteus, pubs_per_mil_per_year, iso3c, color) %>%
  na.omit() %>%
  st_drop_geometry()

names(palette) <- c(1, 2, 3, 4, 5, 6, 7, 8, 9)
ggplot(sp) + 
  geom_text_repel(aes(x=proteus, y=log(pubs_per_mil_per_year*100 + 1),
                 label=iso3c), show.legend=F, size=3) + 
  geom_point(aes(x=proteus, y=log(pubs_per_mil_per_year*100 + 1), fill=color), 
             shape=21, show.legend=F) + 
  scale_fill_manual(values = palette, na.value='#aaaaaa') + 
  theme_minimal() + 
  scale_y_continuous(labels = revlab,
                     breaks = seq(0, log(max(sp$pubs_per_mil_per_year)*100 + 1), length.out = 5)) + 
  labs(x='Proteus Index Score',
       y='Publications Per Million Per Year')
ggsave('C://Users/matt/mine-food-security-tex/img/Bivariate_Plot.pdf', width=10, height=7)

cor(sp$proteus, sp$pubs_per_mil_per_year)




