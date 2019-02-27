#Latent Dirichlet Allocation
#Great documentation here: https://rstudio-pubs-static.s3.amazonaws.com/79360_850b2a69980c4488b1db95987a24867a.html

import pandas as pd
from nltk.corpus import stopwords
from nltk.tokenize import RegexpTokenizer
import textmining
from nltk.stem.snowball import SnowballStemmer
from gensim import corpora, models
import os

with open('filename.pickle', 'rb') as handle:
    ldamod = pickle.load(handle)

data = pd.read_csv('../abstracts.csv', encoding='utf-8')

##################################
#Get each abstracts classification
##################################

abstracts_topics = pd.DataFrame()
for index, row in data.iterrows():
    t = row['text']
    
    #Process in the same way as we did to train the model
    #Tokenize
    tokens = tokenizer.tokenize(t.lower())
    
    #Remove Stopwords
    tokens = [i for i in tokens if not i in stopwords]
    
    #Step Tokens
    tokens = [stemmer.stem(i) for i in tokens]
    
    
    ##Get documents topics
    newdoc = dictionary.doc2bow(tokens)
    topics = ldamodel[newdoc]
    
    #Make dict to become pandas df
    topic_dict = {}
    topic_dict['EID'] = row['EID']
    for topic in topics:
        topic_dict[str(topic[0])] = topic[1]
    
    topic_df = pd.DataFrame(topic_dict, index=[index])
    
    abstracts_topics = abstracts_topics.append(topic_df)
    
    print(float(index)/data.shape[0])

abstracts_topics.to_csv('EIDs and Topic Scores - 200.csv', index=False)

#######################################################
#Get top 15 words for each topic
######################################################

topic_words = ldamodel.print_topics(num_topics=43, num_words=15)

wordranksdf = pd.DataFrame({})
for topic_number in range(0,200):
    #Get top 15 words
    for topic in topic_words:
        if topic[0] == topic_number:
            wordranks = topic[1]
    
    wordranksdf = wordranksdf.append(pd.DataFrame({"Topic_Number": topic_number, "TopWords": wordranks.encode('utf8')}, index=[0]))

wordranksdf.to_csv('Topic Word Ranks - 200.csv', index=False)


