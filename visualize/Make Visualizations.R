library(tidyverse)
library(readxl)
library(zoo)

setwd('G://My Drive/mine-food-security')

abstracts <- read.csv('abstracts.csv', stringsAsFactors = F) %>%
  mutate(ind=seq(0, nrow(.)-1)) %>%
  filter((Type %in% c("Review", "Article")) & (nchar(text) > 500) & CitationCount > 0) %>%
  select(ind, Year, EID)

doc_topic <- read.csv('mod28doc_topic_distribution.csv') %>%
  gather(topic, value, -X) %>%
  mutate(topic = gsub('X', '', topic)) %>%
  rename(ind=X)

labels <- read_excel('mod28topic_abstracts_labelled.xlsx') %>%
  select(topic=k, broadercategory)

doc_topic_labels <- merge(doc_topic, labels)
doc_topic_labels <- doc_topic_labels %>%
  group_by(ind, broadercategory) %>%
  summarize(value = mean(value))


loc <- read.csv('Locations_classified.csv') %>%
  select(EID, verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F)

all <- merge(doc_topic_labels, abstracts_loc) %>%
  na.omit

ts <- all %>% 
  group_by(Year, broadercategory) %>%
  summarize(value=sum(value)) %>%
  group_by(Year) %>%
  mutate(value=value/sum(value))

#Time Series
ggplot(ts) + geom_area(aes(x=Year, y=value, fill=broadercategory)) + 
  ggtitle('Proportion of FS Literature in Each Category Over Time') + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0))
ggsave('G://My Drive/mine-food-security/TimeSeries.png')

ggplot(ts) + geom_line(aes(x=Year, y=value, color=broadercategory)) + 
  ggtitle('Proportion of FS Literature in Each Category Over Time') + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0))

#By Continent
geo <-  all %>% 
  filter(verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  group_by(verdict, broadercategory) %>%
  summarize(value=sum(value)) %>%
  group_by(verdict) %>%
  mutate(value=value/sum(value))

#Geography
ggplot(geo) + geom_bar(aes(x=factor(1), y=value, fill=broadercategory), stat='identity') + 
  coord_polar(theta='y') + 
  facet_wrap(~verdict) + 
  ylab('') + xlab('') +
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid  = element_blank()) + 
  ggtitle('Proportion of FS Literature in Each Category By Continent')
ggsave('G://My Drive/mine-food-security/ByGeography.png')

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
  mutate(count = rollapply(count, 3, FUN=mean, na.rm=TRUE, fill=NA, partial=TRUE)) %>%
  ungroup %>%
  group_by(Year) %>%
  mutate(freq=count/sum(count)) %>%
  rename(Continent=verdict) %>%
  data.frame

#TS Geo
ggplot(ts_geo) + geom_area(aes(x=Year, y=freq, fill=Continent)) + 
  ggtitle('Proportion of FS Literature in Each Continent Over Time', 
          subtitle='With a 3-Year Smoothing') + 
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0))
ggsave('ByCountinent-Year.png')

ggplot(abstracts) + geom_histogram(aes(x=Year), binwidth=1)
ggsave('Histogram Over Time.png')

#TS Policy Topics
doc_topic <- read.csv('mod28doc_topic_distribution.csv') %>%
  gather(topic, value, -X) %>%
  mutate(topic = gsub('X', '', topic)) %>%
  rename(ind=X)

labels <- read_excel('mod28topic_abstracts_labelled.xlsx') %>%
  select(topic=k, broadercategory, theme)

doc_topic_labels <- merge(doc_topic, labels)
doc_topic_labels <- doc_topic_labels %>%
  filter(broadercategory=='policy') %>%
  group_by(ind, theme) %>%
  summarize(value = mean(value))

policy_ts <- merge(doc_topic_labels, abstracts) %>%
  group_by(Year, theme) %>%
  summarize(value=sum(value)) %>%
  group_by(Year) %>%
  mutate(prop=value/sum(value))



ggplot(policy_ts) + geom_area(aes(x=Year, y=prop, fill=theme)) + 
  ggtitle('Proportion of "Policy" FS Literature in Each Topic Over Time') +  
  scale_x_continuous(expand=c(0,0)) + 
  scale_y_continuous(expand=c(0,0))
ggsave('Policy-Topics.png')

ggplot(abstracts) + geom_histogram(aes(x=Year), binwidth=1)
ggsave('Histogram Over Time.png')
