library(readr)
library(topicmodels)
library(dplyr)
library(ggplot2)

setwd('C://Git/mine-food-security/data')

load('ldamod200.Rdata')


data <- read_csv('abstracts.csv')

pos <- posterior(ldamod43)

terms <- pos$terms

termcounts <- apply(terms, 1, function(x){order(x, decreasing = T)[1:15]})
termlabels <- apply(termcounts, 2, function(x){colnames(terms)[x]})

topics <- pos$topics

topicscounts <- apply(topics, 2, function(x){order(x, decreasing = T)[1:10]})
topicstexts <- apply(topicscounts, 2, function(x){data$text[x]})

combdf <- data.frame()
for (i in 1:43){
  topic_terms <- paste0(termlabels[ , i], collapse='; ')
  
  topicdf <- data.frame(Topic_Number=i, Keywords=topic_terms)
  
  for (j in 1:10){
    topicdf[ , paste0("Abstract_", j)] <- topicstexts[j, i]
  }
 
  combdf <- bind_rows(combdf, topicdf) 
}

write.csv(combdf, 'Topics With Keywords and Abstracts - 43 - VEM.csv', row.names=F)

pca <- prcomp(topics)$rotation %>% as.data.frame
pca$label <- row.names(pca)

ggplot(pca) + geom_label(aes(x=PC1, y=PC2, label=label))
