setwd('G://My Drive/mine-food-security/CTMmods')

library(readr)
library(topicmodels)
library(tidyverse)
library(ggplot2)

all <- data.frame()
for (n in c(5, 10, 20, 30, 40, 50, 60, 70, 80)){
  load(paste0('ctm', n, '.Rdata'))
  
  new <- data.frame(k=n, logLik=as.numeric(logLik(ctm)), perplexity=perplexity(ctm)) 

  all <- bind_rows(all, new)    
}

perpl <- seq(850, 1125, 25)
logl <- seq(-13950000, -13400000, 50000)

lm(perpl ~ logl)
lm(logl ~ perpl)

all$perplexity <- all$perplexity*2000 - 15650000

ggplot(all) + 
  geom_line(aes(x=k, y=logLik, color="Log Likelihood")) + 
  geom_line(aes(x=k, y=perplexity, color="Perplexity")) + 
  scale_y_continuous(sec.axis = sec_axis(~(.*0.0005) + 7825,
                                         name="Perplexity")) + 
  theme_bw() + 
  theme(legend.position = c(0.85, 0.5),
        legend.title = element_blank(),
        axis.title.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.text.y=element_blank()) + 
  #geom_vline(aes(xintercept=60), color='darkred', linetype=2) + 
  geom_vline(aes(xintercept=60), color='darkred', linetype=2) +
  xlab('Number of Topics')

ggsave('C://Users/matt/mine-food-security-tex/img/evaluation.eps', width=6, height=4.5)
