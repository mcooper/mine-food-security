#Based on https://cran.r-project.org/web/packages/tm/vignettes/tm.pdf
#and on https://cran.r-project.org/web/packages/ldatuning/vignettes/topics.html

library(tm)
library(readr)
library(SnowballC)
library(ldatuning)
library(topicmodels)

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

##Find Number of Topics
#k <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 20, 25, 30, 35, 40, 45, 60, 55, 60, 70, 80, 90, 100, 120, 140, 160, 180, 200, 250, 300, 350, 400, 450)
k <- seq(20, 80)

result <- FindTopicsNumber(
  dtm,
  topics = k,
  metrics = c("Deveaud2014"),
  method = "Gibbs",
  control = list(seed = 77),
  mc.cores = 4L,
  verbose = TRUE
)

save('result', file='../matt/LDAtuningResultDevaud.Rdata')

FindTopicsNumber_plot(result)

system('curl -s --max-time 10 -d "chat_id=651356346&disable_web_page_preview=1&text=Model done"  https://api.telegram.org/bot624661733:AAHC_iAhhbPDQPPnYKGZ74iUDc2PEu_exRs/sendMessage >/dev/null')



