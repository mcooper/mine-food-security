setwd('G://My Drive/mine-food-security/CTMmods')

library(readr)
library(topicmodels)
library(tidyverse)
library(ggplot2)

all <- data.frame()
for (n in c(5, 10, 20, 30, 40, 50, 60, 70)){
  load(paste0('ctm', n, '.Rdata'))
  
  new <- data.frame(k=n, logLik=as.numeric(logLik(ctm)), perplexity=perplexity(ctm)) 

  all <- bind_rows(all, new)    
}

all <- all %>%
  gather(metric, score, -k)

ggplot(all) + geom_line(aes(x=k, y=score, color=metric)) + 
  facet_wrap(metric ~ ., scales = 'free_y')
