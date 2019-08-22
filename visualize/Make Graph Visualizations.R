library(glmnet)
library(readr)
library(readxl)
library(tidyverse)
library(topicmodels)

k <- 60

topics <- 1:(k-1)

setwd('G://My Drive/mine-food-security/CTMmods')

load(paste0('ctm', k, '.Rdata'))

labels <- read_xlsx(paste0('../CTM', k, ' - Topics_Final Matt Update.xlsx')) %>%
  filter(`Topic Name` != '---- Mashup Topic -----' & Topic_Number != k)

#Make Graph
mat <- ctm@nusquared

graphmat <- matrix(nrow=(ctm@k - 1), ncol=(ctm@k - 1))
rownames(graphmat) <- topics
colnames(graphmat) <- topics

lambda <- 0.45

for (i in topics){
  y <- mat[ , i]
  X <- mat[ , topics[topics != i]]
  
  coefs <- coef(glmnet(X, y, lambda=lambda))
  
  graphmat[topics[topics != i], i] <- coefs[2:nrow(coefs), ]
  
}

diag(graphmat) <- 0

for (i in topics){
  for (j in topics){
    if (graphmat[i, j] > 0 & graphmat[j, i] > 0){
      graphmat[i, j] <- TRUE
      graphmat[j, i] <- TRUE
    } else{
      graphmat[i, j] <- FALSE
      graphmat[j, i] <- FALSE
    }
  }
}

library(sna)
library(ggplot2)
library(ggnetwork)

net <- network(graphmat[labels$Topic_Number, labels$Topic_Number], directed = FALSE)

sizes <- cut(labels$Perc_of_Corpus[topics], breaks=3)
levels(sizes) <- c('small', 'medium', 'large')

simpleCap <- function(x) {
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

net %v% "Theme" <- sapply(labels$`Group Names`[topics], simpleCap)
net %v% "Food Security Pillar" <- sapply(labels$`Food Security category`[topics], simpleCap)
net %v% "size" <- labels$Perc_of_Corpus[topics]
net %v% "label" <- gsub(' ', '\n', sapply(labels$`Topic Name`, simpleCap))

#can use any of these placement algoriths
#http://melissaclarkson.com/resources/R_guides/documents/gplot_layout_Ver1.pdf

set.seed(50)
dat <- ggnetwork(net, layout="fruchtermanreingold")

ggplot(dat, aes(x = x, y = y, xend = xend, yend = yend)) + 
  geom_edges() + 
  geom_nodes(aes(size=size, color=`Food Security Pillar`), alpha=0.9) + 
  scale_size_area(guide='none', max_size=20) + 
  geom_nodetext(aes(label=label), size=2) +
  scale_color_brewer(palette = "Set3") + 
  theme_blank() + 
  guides(color=guide_legend(title="Food Security Pillar"))
ggsave('C://Users/matt/mine-food-security-tex/img/graph60_fslabels.png', width=11.5, height=6)

