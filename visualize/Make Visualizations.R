library(tidyverse)
library(readxl)
library(zoo)

setwd('G://My Drive/mine-food-security')

abstracts <- read.csv('abstracts_final.csv', stringsAsFactors = F) %>%
  mutate(ind=seq(0, nrow(.)-1)) %>%
  select(ind, Year, EID)

doc_topic <- read.csv('CTMmods/CTM60 - Doc Topic Matrix.csv') %>%
  gather(topic, value, -X) %>%
  mutate(topic = gsub('X', '', topic)) %>%
  rename(ind=X)

labels <- read_excel('CTM60 - Topics_Final.xlsx') %>%
  filter(`Topic Name` != '---- Mashup Topic -----') %>%
  select(topic=Topic_Number, Theme=`Group Names`, `FS Theme`=`Food Security category`)

doc_topic_labels <- merge(doc_topic, labels, all.x=FALSE, all.y=T)
doc_topic_labels <- doc_topic_labels %>%
  group_by(ind, theme) %>%
  summarize(value = mean(value))


loc <- read.csv('Locations_classified.csv') %>%
  select(EID, verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F)

all <- merge(doc_topic_labels, abstracts_loc) %>%
  na.omit

alldf <- expand.grid(seq(1975, 2019), unique(all$Theme))
names(alldf) <- c('Year', 'Theme')

ts <- all %>% 
  group_by(Year, Theme) %>%
  summarize(value=sum(value)) %>%
  merge(alldf, all.x=T, all.y=T) %>%
  mutate(value = ifelse(is.na(value), 0, value)) %>%
  group_by(Theme) %>%
  arrange(Year) %>%
  mutate(value = rollapply(value, 5, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(value=value/sum(value)) %>%
  data.frame

#Time Series
ggplot(ts) + geom_area(aes(x=Year, y=value, fill=Theme)) + 
  ggtitle('Proportion of FS Literature in Each Category Over Time', 
          subtitle='With a 5-Year Smoothing') + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_brewer(palette = "Set3")
ggsave('C://Git/mine-food-security-tex/img/TimeSeries.png')

alldf <- expand.grid(seq(1975, 2019), unique(all$`FS Theme`))
names(alldf) <- c('Year', 'FS Theme')

ts <- all %>% 
  group_by(Year, `FS Theme`) %>%
  summarize(value=sum(value)) %>%
  merge(alldf, all.x=T, all.y=T) %>%
  mutate(value = ifelse(is.na(value), 0, value)) %>%
  group_by(`FS Theme`) %>%
  arrange(Year) %>%
  mutate(value = rollapply(value, 5, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(value=value/sum(value)) %>%
  data.frame

#Time Series
ggplot(ts) + geom_area(aes(x=Year, y=value, fill=FS.Theme)) + 
  ggtitle('Proportion of FS Literature in Each Category Over Time', 
          subtitle='With a 5-Year Smoothing') + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_brewer(palette = "Set3")
ggsave('C://Git/mine-food-security-tex/img/TimeSeries_FS.png')

#By Continent
geo <-  all %>% 
  filter(verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  group_by(verdict, Theme) %>%
  summarize(value=sum(value)) %>%
  group_by(verdict) %>%
  mutate(value=value/sum(value))

#Geography
ggplot(geo) + geom_bar(aes(x=factor(1), y=value, fill=Theme), stat='identity') + 
  coord_polar(theta='y') + 
  facet_wrap(~verdict) + 
  ylab('') + xlab('') +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid  = element_blank()) + 
  ggtitle('Proportion of FS Literature in Each Category By Continent') +
  scale_fill_brewer(palette = "Set3")
ggsave('C://Git/mine-food-security-tex/img/ByGeography.png')

#By Continent
geo <-  all %>% 
  filter(verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  group_by(verdict, `FS Theme`) %>%
  summarize(value=sum(value)) %>%
  group_by(verdict) %>%
  mutate(value=value/sum(value))

#Geography
ggplot(geo) + geom_bar(aes(x=factor(1), y=value, fill=`FS Theme`), stat='identity') + 
  coord_polar(theta='y') + 
  facet_wrap(~verdict) + 
  ylab('') + xlab('') +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid  = element_blank()) + 
  ggtitle('Proportion of FS Literature in Each Category By Continent') +
  scale_fill_brewer(palette = "Set3")
ggsave('C://Git/mine-food-security-tex/img/ByGeographyFS.png')


alldf <- expand.grid(seq(1975, 2019), c('Africa', 'Asia', 'First World', 'LAC'))
names(alldf) <- c('Year', 'verdict')

ts_geo <- abstracts_loc %>%
  filter(verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  group_by(Year, verdict) %>%
  summarize(count = n()) %>%
  merge(alldf, all.x=T, all.y=T) %>%
  mutate(count = ifelse(is.na(count), 0, count)) %>%
  group_by(verdict) %>%
  arrange(Year) %>%
  mutate(count = rollapply(count, 5, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(freq=count/sum(count)) %>%
  rename(Continent=verdict) %>%
  data.frame

#TS Geo
ggplot(ts_geo) + geom_area(aes(x=Year, y=freq, fill=Continent)) + 
  ggtitle('Proportion of FS Literature in Each Continent Over Time', 
          subtitle='With a 5-Year Smoothing') + 
  scale_x_continuous(expand=c(0,0), limits = c(1980, 2019)) + 
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_brewer(palette = "Set3")
ggsave('C://Git/mine-food-security-tex/img/ByCountinent-Year.png')

ggplot(abstracts) + geom_histogram(aes(x=Year), binwidth=1)
ggsave('Histogram Over Time.png')
