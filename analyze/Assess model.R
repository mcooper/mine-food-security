library(readr)
library(topicmodels)
library(dplyr)
library(ggplot2)
library(tidyr)

setwd('G://My Drive/mine-food-security/CTMmods')

load('ctm40.Rdata')

data <- read_csv('../abstracts.csv') %>%
  data.frame %>%
  filter((Type %in% c("Review", "Article")) & (nchar(text) > 500) & CitationCount > 0)

#write.csv(data, '../abstracts_final.csv', row.names=F, fileEncoding = "UTF-8")

pos <- posterior(ctm)

terms <- pos$terms

termcounts <- apply(terms, 1, function(x){order(x, decreasing = T)[1:15]})
termlabels <- apply(termcounts, 2, function(x){colnames(terms)[x]})

topics <- pos$topics

topicscounts <- apply(topics, 2, function(x){order(x, decreasing = T)[1:10]})
topicstexts <- apply(topicscounts, 2, function(x){data$text[x]})

combdf <- data.frame()
for (i in 1:ctm@k){
  topic_terms <- paste0(termlabels[ , i], collapse='; ')
  
  topicdf <- data.frame(Topic_Number=i, Keywords=topic_terms)
  
  for (j in 1:10){
    topicdf[ , paste0("Abstract_", j)] <- topicstexts[j, i]
  }
  
  combdf <- bind_rows(combdf, topicdf) 
}

combdf$Perc_of_Corpus <- colSums(pos$topics)/sum(pos$topics)*100

write.csv(combdf, paste0('CTM', ctm@k, ' - Topics With Keywords and Abstracts.csv'), row.names=F)
write.csv(pos$terms, paste0('CTM', ctm@k, ' - Topic Word Matrix.csv'))
write.csv(pos$topics, paste0('CTM', ctm@k, ' - Doc Topic Matrix.csv'))

#################################################################################################
#Try to get Blei's graph from covariance matrix based on Meinshausen and Buhlmann using the Lasso
###################################################################################################

#Sigma is k-1 by k-1 for some reason, documentation here:
#https://web.archive.org/web/20100708221246/https://lists.cs.princeton.edu/pipermail/topic-models/2010-April/000813.html

library(glmnet)
library(broom)
#Still dont know: do I use Sigma or nusquared?  I think nusquared because Blei talks about "documents"
mat <- ctm@Sigma
mat <- ctm@nusquared

for (l in c(0.1, 0.25, 0.5, 0.75, 0.9, 1)){
  
  lambda <- l #Have to pick lambda (called \rho_n in the Blie paper). Higer values=less connection
  
  topics <- 1:(ctm@k - 1)
  
  graphmat <- matrix(nrow=(ctm@k - 1), ncol=(ctm@k - 1))
  for (i in topics){
    y <- mat[ , i]
    X <- mat[ , topics[topics != i]]
    
    coefs <- coef(glmnet(X, y, lambda=lambda))
    
    graphmat[topics[topics != i], i] <- coefs[2:nrow(coefs), ]
    
  }
  
  library(stringr)
  
  nodes <- combdf %>%
    select(nodes=Keywords, id=Topic_Number) %>%
    rowwise() %>%
    mutate(id=id - 1, 
           nodes = gsub('; ', '\n', substr(nodes, 1, str_locate_all(nodes, '; ')[[1]][4, 2])))
  
  edges <- graphmat %>%
    data.frame %>%
    mutate(start=row.names(.)) %>%
    gather(end, value, -start) %>%
    filter(!is.na(value) & value > 0) %>%
    mutate(end=as.numeric(gsub('X', '', end))-1,
           start=as.numeric(start)-1, 
           value=1) %>%
    filter(paste0(start, end) %in% paste0(end, start))
  
  
  library(networkD3)
  
  f <- forceNetwork(Links=edges, Nodes=nodes, Source='start', Target='end', 
               NodeID="nodes", Value='value', Group='id', fontSize=15, height=500, width=750, bounded=T)
  saveNetwork(f, paste0('C://Git/mcooper.github.io/ctm', ctm@k, '-', l*100, '.html'), selfcontained=T)
}
