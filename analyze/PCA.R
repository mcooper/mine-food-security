library(dplyr)
library(tidyverse)
library(RColorBrewer)
library(factoextra)
library(ggplot2)
library(tidygraph)
library(ggraph)
library(ggpubr)
library(cowplot)
library(ggcorrplot)
library(ggrepel)
library(GGally)


options(stringsAsFactors=F)

setwd('C://Git/mine-food-security/data')

abstract_topics <- read.csv('EIDs and Topic Scores.csv')

row.names(abstract_topics) <- abstract_topics$EID

abstract_topics <- abstract_topics %>% 
  select(-EID) %>%
  as.matrix

abstract_topics[is.na(abstract_topics)] <- 0

res.pca <- prcomp(abstract_topics, scale = TRUE)

df <- data.frame(res.pca$rotation)
df$label <- gsub('X', '', row.names(df))

ggplot(df) + geom_label(aes(x=PC1, y=PC2, label=label))
