library(tidyverse)

setwd('G://My Drive/mine-food-security')

abstracts <- read.csv('abstracts.csv') %>%
  mutate(ind=seq(0, nrow(abstracts)-1)) %>%
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
  ggtitle('Proportion of FS Literature in Each Category Over By Continent')
ggsave('G://My Drive/mine-food-security/ByGeography.png')

