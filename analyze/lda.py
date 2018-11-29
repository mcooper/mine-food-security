#Latent Dirichlet Allocation
#Great documentation here: https://rstudio-pubs-static.s3.amazonaws.com/79360_850b2a69980c4488b1db95987a24867a.html

import pandas as pd
from nltk.corpus import stopwords
from nltk.tokenize import RegexpTokenizer
import textmining
from nltk.stem.snowball import SnowballStemmer
from gensim import corpora, models

data = pd.read_csv('C://Git/mine-food-security/data/abstracts.csv', encoding='utf-8')
abstracts = data['text'].tolist()

tdm = textmining.TermDocumentMatrix()

tokenizer = RegexpTokenizer(r'\w+')
stopwords = textmining.read_stopwords()

#Get rid of small numbers
stopwords = list(stopwords) + map(str, range(100))

#Add Food and Security and Insecurity, because they will be in every abstract
stopwords = stopwords + ["food", "security", "insecurity"]

#Add other stopwords that likely appear in many abstracts and arent very topical
stopwords = stopwords + ["study", "studies", "studied", "paper", "papers", "article", "articles"]

stemmer = SnowballStemmer("english")

texts = []
for t in abstracts:
    #Tokenize
    tokens = tokenizer.tokenize(t.lower())
    
    #Remove Stopwords
    tokens = [i for i in tokens if not i in stopwords]
    
    #Step Tokens
    tokens = [stemmer.stem(i) for i in tokens]
    
    texts.append(tokens)

dictionary = corpora.Dictionary(texts)
corpus = [dictionary.doc2bow(text) for text in texts]

ldamodel = models.ldamodel.LdaModel(corpus, num_topics=6, id2word = dictionary, passes=40)

res = ldamodel.print_topics(num_topics=6, num_words=10)






