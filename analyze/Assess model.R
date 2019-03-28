library(readr)
library(topicmodels)
library(dplyr)
library(ggplot2)
library(philentropy)

setwd('C://Git/mine-food-security/data')

load('ldamod200.Rdata')


data <- read_csv('abstracts.csv')

pos <- posterior(ctm)

terms <- pos$terms

termcounts <- apply(terms, 1, function(x){order(x, decreasing = T)[1:15]})
termlabels <- apply(termcounts, 2, function(x){colnames(terms)[x]})

topics <- pos$topics

topicscounts <- apply(topics, 2, function(x){order(x, decreasing = T)[1:10]})
topicstexts <- apply(topicscounts, 2, function(x){data$text[x]})

combdf <- data.frame()
for (i in 1:30){
  topic_terms <- paste0(termlabels[ , i], collapse='; ')
  
  topicdf <- data.frame(Topic_Number=i, Keywords=topic_terms)
  
  for (j in 1:10){
    topicdf[ , paste0("Abstract_", j)] <- topicstexts[j, i]
  }
  
  combdf <- bind_rows(combdf, topicdf) 
}

write.csv(combdf, 'CTM - Topics With Keywords and Abstracts - 30.csv', row.names=F)
write.csv(pos$terms, 'CTM - Topic Word Matrix.csv')
write.csv(pos$topics, 'CTM - Doc Topic Matrix.csv')

m <- matrix(nrow=30, ncol=30)

jsd <- sqrt(JSD(pos$terms))

jsd_scale1 <- (jsd - min(jsd[jsd!=0]))
jsd_scale <- jsd_scale1/max(jsd_scale1)
diag(jsd_scale) <- 0

jsd_mds <- cmdscale(jsd, k=2)
jsd_scale_mds <- cmdscale(jsd_scale, k=2)

write.csv(jsd_mds, 'CTM - JSD.csv')
write.csv(jsd_scale_mds, 'CTM - JSD scale.csv')


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

lambda <- 0.5 #Have to pick lambda (called \rho_n in the Blie paper)

topics <- 1:(ctm@k - 1)

graphmat <- matrix(nrow=(ctm@k - 1), ncol=(ctm@k - 1))
for (i in topics){
  y <- mat[ , i]
  X <- mat[ , topics[topics != i]]
  
  coefs <- coef(glmnet(X, y, lambda=lambda))
  
  graphmat[topics[topics != i], i] <- coefs[2:nrow(coefs), ]
  
}





