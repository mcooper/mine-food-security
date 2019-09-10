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

edgelist <- data.frame()
for (lambda in seq(0.05, 1, 0.05)){
  print(lambda) #lambda is \rho_n in Blei paper
  
  graphmat <- matrix(data = rep(0, (ctm@k - 1)^2),
                     nrow=(ctm@k - 1), 
                     ncol=(ctm@k - 1))
  rownames(graphmat) <- topics
  colnames(graphmat) <- topics
  
  #Get LASSO coefficients
  for (i in topics){
    y <- mat[ , i]
    X <- mat[ , topics[topics != i]]
    
    coefs <- coef(glmnet(X, y, alpha=1, lambda=lambda))
    
    graphmat[topics[topics != i], i] <- coefs[2:nrow(coefs), ]
    
  }

  #Determine if AND.  If so, increment edgelist
  for (i in topics){
    for (j in topics){
      
      #If both coefficients are greater than 0 (AND Case)
      if (graphmat[i, j] > 0 & graphmat[j, i] > 0){
        
        #if i > j (undirected graph, so skip cases where j > i)
        if (i > j){ 
          
          #If edge is already in edgelist, increment attribute
          if ((i %in% edgelist$i) & (j %in% edgelist$j)){
            
            edgelist[edgelist$i == i & edgelist$j == j, 'lambda'] <- max(c(edgelist[edgelist$i == i & edgelist$j == j, 'lambda'], lambda))
          
            } else{
            
            #Else add new edge to edgelist
            edgelist <- bind_rows(edgelist, data.frame(i=i, j=j, lambda=lambda))
          }
        }
      }
    }
  }
}

l <- data.frame()
for (i in seq(1, 59)){
  l <- bind_rows(l,
                 data.frame(topic=i,
                            degrees=sum(edgelist$lambda[edgelist$i==i]) + sum(edgelist$lambda[edgelist$j==i])))
}

write.csv(edgelist %>% 
            rename(Source=i, Target=j) %>%
            filter(Source %in% labels$Topic_Number & Target %in% labels$Topic_Number), 
          'G://My Drive/mine-food-security/gephi data/edges.csv', row.names=F)

write.csv(labels %>%
            select(Id=Topic_Number,
                   Label=`Topic Name`,
                   Size=Perc_of_Corpus,
                   Theme=`Group Names`,
                   Pillar=`Food Security category`),
          'G://My Drive/mine-food-security/gephi data/nodes.csv', row.names=F)
