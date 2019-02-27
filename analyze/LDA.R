#Based on https://cran.r-project.org/web/packages/tm/vignettes/tm.pdf
#and on https://cran.r-project.org/web/packages/ldatuning/vignettes/topics.html

library(tm)
library(readr)
library(SnowballC)
library(ldatuning)
library(topicmodels)

setwd('C://Git/mine-food-security/data')

data <- read_csv('abstracts.csv')

corp <- VCorpus(VectorSource(data$text))

#Do Transformations
#Remove Whitespace
corp <- tm_map(corp, stripWhitespace)

#Convert to Lower
corp <- tm_map(corp, content_transformer(tolower))

#Remove punctuation
corp <- tm_map(corp, removePunctuation, ucp=TRUE)

#Remove Stopwords
#Also remove "food", "security", and "insecurity" because they are in literally every abstract
corp <- tm_map(corp, removeWords, c(stopwords("english"), "food", "security", "insecurity"))

#Stemming
corp <- tm_map(corp, stemDocument)

##Make DTM
dtm <- DocumentTermMatrix(corp)

#Remove words that only occur in n documents
n <- 1
dtm <- removeSparseTerms(dtm, sparse=(1 - n/dtm[[4]]))


#Run Model
ldamod43 <- LDA(dtm, k = 43, method = "Gibbs")

ldamod200 <- LDA(dtm, k = 43, method = "Gibbs")


save(ldamod43, file = "ldamod43.Rdata")
save(ldamod200, file = "ldamod200.Rdata")

system('/home/mattcoop/telegram.sh "Models Done!"')