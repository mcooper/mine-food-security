#Based on https://cran.r-project.org/web/packages/tm/vignettes/tm.pdf
#and on https://cran.r-project.org/web/packages/ldatuning/vignettes/topics.html

library(tm)
library(readr)
library(SnowballC)
library(topicmodels)
library(dplyr)
library(doParallel)

data <- read_csv('/home/mattcoop/abstracts.csv') %>%
  data.frame %>%
  filter((Type %in% c("Review", "Article")) & (nchar(text) > 500) & CitationCount > 0)

corp <- VCorpus(VectorSource(data$text))

#Do Transformations
#Remove Whitespace
corp <- tm_map(corp, stripWhitespace)

#Convert to Lower
corp <- tm_map(corp, content_transformer(tolower))

#Remove punctuation
corp <- tm_map(corp, removePunctuation, ucp=TRUE)

#Remove numbers
corp <- tm_map(corp, removeNumbers)

#Remove Stopwords
#Also remove "food", "security", and "insecurity" because they are in literally every abstract
corp <- tm_map(corp, removeWords, c(stopwords("english"), "food", "security", "insecurity"))

#Stemming
corp <- tm_map(corp, stemDocument)

#Define Bigram Tokenizer
BigramTokenizer <- function(x){
  out <- words(x)
  bigrams <- unlist(lapply(ngrams(words(x), 2), paste, collapse = "_"), use.names = FALSE)
  out <- c(out, bigrams)
  out
}

##Make DTM
dtm <- DocumentTermMatrix(corp, control = list(tokenize=BigramTokenizer))

# Explore Terms
# m <- as.matrix(dtm)
# m2 <- colSums(m)
# m2 <- m2/dtm[[4]]
# m3 <- m2[order(m2)]

#Remove words that only occur in n documents
#Blei removed those that occur fewer than 70 times
n <- 70
dtm <- removeSparseTerms(dtm, sparse=(1 - n/dtm[[4]]))


############################
#Run models
#############################

cl <- makeCluster(4, outfile = '')
registerDoParallel(cl)

system('/home/mattcoop/telegram.sh "Starting CTM models"')

ks <- c(5, seq(10, 120, 10))

foreach(k=ks, .packages=c('tm', 'topicmodels')) %dopar% {
  
  #Run Model
  ctm <- CTM(dtm, k, method = 'VEM')
  
  save(ctm, file = paste0("CTMmods/ctm", k, ".Rdata"))
  
  system(paste0('/home/mattcoop/telegram.sh "CTM Model ', k, ' Done!"'))
  
}
