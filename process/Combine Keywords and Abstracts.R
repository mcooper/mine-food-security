library(dplyr)

options(stringsAsFactors=F)

setwd('C://Git/mine-food-security/data')

abstract_topics <- read.csv('EIDs and Topic Scores.csv')
abstracts <- read.csv('abstracts.csv')
wordranks <- read.csv('Topic Word Ranks.csv')

just_topics <- abstract_topics %>% select(-EID)

rates <- colSums(just_topics, na.rm=T)/sum(just_topics, na.rm=T)

all_topic_df <- data.frame()
for (topicnumber in seq(0, 42)){
  wordrank <- wordranks[wordranks$Topic_Number == topicnumber, 'TopWords']
  wordrank <- gsub('"', '', gsub(" \\+ ", "; ", gsub('0....\\*', '', wordrank)), fixed=T)
  
  col <- paste0("X", topicnumber)
  
  eids <- abstract_topics$EID[order(abstract_topics[ , col], decreasing=TRUE)[1:10]]
  
  topic_df <- data.frame(Topic_Number=topicnumber, Top_Words=wordrank, Percent_of_Corpus=rates[[col]]*100)
  
  for (i in 1:10){
    text <- abstracts[abstracts$EID==eids[i], 'text']
  
    topic_df[ ,paste0("Abstract_", i)] <- text
  }
  
  all_topic_df <- bind_rows(all_topic_df, topic_df)
}

write.csv(all_topic_df, 'Topics With Keywords and Abstracts.csv', row.names=F)