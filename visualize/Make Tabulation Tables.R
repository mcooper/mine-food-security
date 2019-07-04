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

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

labels <- read_excel('CTM60 - Topics_Final Matt Update.xlsx') %>%
  filter(`Topic Name` != '---- Mashup Topic -----') %>%
  select(topic=Topic_Number, topic_name=`Topic Name`, Theme=`Group Names`, `FS Theme`=`Food Security category`) %>%
  mutate(topic_name = sapply(topic_name, simpleCap))

doc_topic_labels <- merge(doc_topic, labels, all.x=FALSE, all.y=T)

loc <- read.csv('Abstract_locations_classified.csv') %>%
  select(EID, con_verdict, cty_verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F)

all <- merge(doc_topic_labels, abstracts_loc) %>%
  na.omit

all %>%
  group_by(con_verdict, topic_name) %>%
  summarize(value=round(sum(value))) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  spread(con_verdict, value) %>%
  rename(HICs=`First World`, `Topic Name`=topic_name) %>%
  xtable(caption='Tabulation of abstracts by topic and world region', label='tab:topic_tab', 
         align=c('l', 'l', 'r', 'r', 'r', 'r'), digits=0) %>%
  print(file='C://Users/matt/mine-food-security-tex/tables/topic_tab.tex',
        include.rownames=F, include.colnames=T, 
        size="\\fontsize{9pt}{10pt}\\selectfont")

all %>%
  group_by(con_verdict, Theme) %>%
  summarize(value=round(sum(value))) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  spread(con_verdict, value) %>%
  rename(HICs=`First World`) %>%
  xtable(caption='Tabulation of abstracts by theme and world region', label='tab:theme_tab', 
              align=c('l', 'l', 'r', 'r', 'r', 'r'), digits=0) %>%
  print(file='C://Users/matt/mine-food-security-tex/tables/theme_tab.tex',
      include.rownames=F, include.colnames=T)
