setwd('G://My Drive/mine-food-security')

library(tidyverse)

dat <- read.csv('LDAmod_evaluation.csv')

dat <- dat %>%
  gather(metric, value, -k) %>%
  merge(data.frame(metric=c('arun', 'caojuan', 'coherence', 'perplexity'),
                   optimize=c('minimize', 'minimize', 'maximize', 'minimize')))

sel <- dat %>%
  filter(k > 30 & k < 52)

ggplot(dat) + geom_line(aes(x=k, y=value, color=optimize)) + 
  facet_grid(metric~., scales='free_y')

#Minimize: Cao-Juan, Arun, Perplexity
#Maximize: Coherence, 