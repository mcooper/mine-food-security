library(glmnet)
library(readr)
library(readxl)
library(tidyverse)
library(topicmodels)

setwd('G://My Drive/mine-food-security/CTMmods')

load('ctm40.Rdata')

labels <- read_xlsx('../CTM40 - Topics.xlsx')

#Make Graph
topics <- 1:39

mat <- ctm@nusquared

graphmat <- matrix(nrow=(ctm@k - 1), ncol=(ctm@k - 1))
rownames(graphmat) <- topics
colnames(graphmat) <- topics

lambda <- 0.8

for (i in topics){
  y <- mat[ , i]
  X <- mat[ , topics[topics != i]]
  
  coefs <- coef(glmnet(X, y, lambda=lambda))
  
  graphmat[topics[topics != i], i] <- coefs[2:nrow(coefs), ]
  
}

graphmat <- graphmat > 0

library(GGally)
library(network)
library(sna)
library(ggplot2)
library(ggnetwork)

coldf <- data.frame(lab=unique(labels$`New group names`),
                col=c('#8dd3c7','#ffffb3','#bebada','#fb8072','#80b1d3','#fdb462','#b3de69','#fccde5','#d9d9d9'))

sel <- data.frame(lab=labels$`New group names`[1:39],
                  seq=1:39)
new <- merge(sel, coldf) %>%
  arrange(seq)

new$col <- as.character(new$col)

net <- network(graphmat, directed = FALSE)

sizes <- cut(labels$Perc_of_Corpus[1:39], breaks=3)
levels(sizes) <- c('small', 'medium', 'large')

net %v% "theme" <- labels$`New group names`[1:39]
net %v% "size" <- labels$Perc_of_Corpus[1:39]
net %v% "label" <- 1:39

#can use any of these placement algoriths
#http://melissaclarkson.com/resources/R_guides/documents/gplot_layout_Ver1.pdf
dat <- ggnetwork(net, layout="fruchtermanreingold")

ggplot(dat, aes(x = x, y = y, xend = xend, yend = yend)) + 
  geom_edges() + 
  geom_nodes(aes(size=size, color=theme), alpha=0.9) + 
  scale_size_area(guide='none', max_size=20) + 
  geom_nodetext(aes(label=label)) +
  scale_color_brewer(palette = "Set3") + 
  theme_blank()
ggsave('C://Git/mine-food-security-tex/img/graph.png', width=7, height=4)

