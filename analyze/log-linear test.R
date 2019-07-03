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

loc <- read.csv('Abstract_locations_classified.csv') %>%
  select(EID, con_verdict, cty_verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F)

all <- merge(doc_topic_labels, abstracts_loc) %>%
  na.omit

con_tab <- all %>%
  group_by(con_verdict, topic) %>%
  summarize(value=sum(value)) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC'))


#Proceeding based on this nice tutorial:
#https://data.library.virginia.edu/an-introduction-to-loglinear-models/
mod <- glm(value ~ con_verdict + topic, data=con_tab, family=poisson)
pchisq(deviance(mod), df = df.residual(mod), lower.tail = F)

mod2 <- glm(value ~ (con_verdict + topic)^2, 
                    data = con_tab, family = poisson)
pchisq(deviance(mod2), df = df.residual(mod2), lower.tail = F)

anova(mod, mod2)
