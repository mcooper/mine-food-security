library(tidyverse)
library(readxl)
library(zoo)
library(texreg)

setwd('G://My Drive/mine-food-security')

options(stringsAsFactors=FALSE)

abstracts <- read.csv('abstracts_final.csv') %>%
  mutate(ind=seq(0, nrow(.)-1)) %>%
  select(ind, Year, EID)

doc_topic <- read.csv('CTMmods/CTM60 - Doc Topic Matrix.csv') %>%
  gather(topic, value, -X) %>%
  mutate(topic = gsub('X', '', topic)) %>%
  rename(ind=X)

labels <- read_excel('CTM60 - Topics_Final Matt Update.xlsx') %>%
  filter(`Topic Name` != '---- Mashup Topic -----') %>%
  select(topic=Topic_Number, Theme=`Group Names`, `FS Theme`=`Food Security category`)

doc_topic_labels <- merge(doc_topic, labels, all.x=FALSE, all.y=T)

loc <- read.csv('Abstract_locations_classified.csv') %>%
  select(EID, con_verdict, cty_verdict)

abstracts_loc <- merge(abstracts, loc, all.x=T, all.y=F)

all <- merge(doc_topic_labels, abstracts_loc) %>%
  na.omit

topic_tab <- all %>%
  group_by(con_verdict, topic) %>%
  summarize(value=round(sum(value))) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  ungroup %>%
  mutate(con_verdict = ifelse(con_verdict=='First World', 'HICs', con_verdict))

theme_tab <- all %>%
  group_by(con_verdict, Theme) %>%
  summarize(value=round(sum(value))) %>%
  filter(con_verdict %in% c('Africa', 'Asia', 'First World', 'LAC')) %>%
  ungroup %>%
  mutate(con_verdict = ifelse(con_verdict=='First World', 'HICs', con_verdict),
         Theme = ifelse(Theme=='Climate & Sustainability', 'Climate And Sustainability', Theme)) %>%
  rename(Region=con_verdict)


#Proceeding based on this nice tutorial:
#https://data.library.virginia.edu/an-introduction-to-loglinear-models/


#Lower order theme model
mod <- glm(value ~ Region + Theme, data=theme_tab, family=poisson)
pchisq(deviance(mod), df = df.residual(mod), lower.tail = F)

texreg(mod, caption='First-Order Log-Linear Model', label='tab:firstOrderLL',
       custom.model.names='Model', float.pos='H',
       file='C://Users/matt/mine-food-security-tex/tables/firstOrderLL.tex')

#Higher order theme model
mod2 <- glm(value ~ (Region + Theme)^2, 
                    data = theme_tab, family = poisson)
pchisq(deviance(mod2), df = df.residual(mod2), lower.tail = F)

texreg(mod2, caption='Second-Order Log-Linear Model', label='tab:secondOrderLL', 
       custom.model.names='Model', longtable=TRUE, use.packages=FALSE,
       file='C://Users/matt/mine-food-security-tex/tables/secondOrderLL.tex')


#Lower order topic model
mod3 <- glm(value ~ con_verdict + topic, data=topic_tab, family=poisson)
pchisq(deviance(mod3), df = df.residual(mod3), lower.tail = F)

#Higher order topic model
mod4 <- glm(value ~ (con_verdict + topic)^2, 
            data = topic_tab, family = poisson)
pchisq(deviance(mod4), df = df.residual(mod4), lower.tail = F)
