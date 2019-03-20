setwd('G://My Drive/mine-food-security')

library(tidyverse)

dat <- read.csv('LDAmod_evaluation.csv')

dat <- dat %>%
  gather(metric, value, -k)

sel <- dat %>%
  filter(k > 30 & k < 52)

ggplot(sel) + geom_line(aes(x=k, y=value, color=metric)) + 
  facet_grid(metric~., scales='free_y')

