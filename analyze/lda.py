#Latent Dirichlet Allocation
#Great documentation here: https://rstudio-pubs-static.s3.amazonaws.com/79360_850b2a69980c4488b1db95987a24867a.html

import pandas as pd
from nltk.tokenize import RegexpTokenizer
from nltk.corpus import stopwords
from nltk.stem.snowball import SnowballStemmer
from gensim import corpora, models
from gensim.models import Phrases
import os
import pickle

#os.chdir('C://Git/mine-food-security/data/')

data = pd.read_csv('abstracts.csv', encoding='utf-8')
abstracts = data['text'].tolist()

tokenizer = RegexpTokenizer(r'\w+')
stopwords = stopwords.words('english')

#Get rid of small numbers
stopwords = list(stopwords) + list(map(str, range(1001)))

#Add Food and Security and Insecurity, because they will be in every abstract
stopwords = stopwords + ["food", "security", "insecurity"]

#Add other stopwords that likely appear in many abstracts and arent very topical
stopwords = stopwords + ["study", "studies", "studied", "paper", "papers", 
                         "article", "articles", "abstract", "abstracts", 
                         "objective", "objectives", "result", "conculsion" 
                         "results", "conclusions", "purpose", "purposes", 
                         "methods", "method", "methodology", "approaches",
                         "data", "introduction", "approach"]

stemmer = SnowballStemmer("english")

texts = []
for t in abstracts:
    #Tokenize
    tokens = tokenizer.tokenize(t.lower())
    
    #Remove Stopwords
    tokens = [i for i in tokens if not i in stopwords]
    
    #Stem Tokens
    tokens = [stemmer.stem(i) for i in tokens]
    
    #remove short strings
    tokens = [i for i in tokens if len(i) > 2]
    
    texts.append(tokens)

bigram = Phrases(texts, min_count=20)
for idx in range(len(texts)):
    for token in bigram[texts[idx]]:
        if '_' in token:
            # Token is a bigram, add to document.
            texts[idx].append(token)

dictionary = corpora.Dictionary(texts)
dictionary.filter_extremes(no_below=10, no_above=0.5)
corpus = [dictionary.doc2bow(text) for text in texts]

ks = list(range(2, 50, 3)) + list(range(50, 100, 5)) + list(range(100, 150, 10)) + list(range(150, 201, 25)) 

try:
	for k in ks:
		print(k)
		
		ldamodel = models.ldamulticore.LdaMulticore(corpus, num_topics=k, id2word = dictionary, passes=40, workers=3)
		
		with open('LDAmods/mod' + str(k), 'wb') as handle:
			pickle.dump(ldamodel, handle, protocol=pickle.HIGHEST_PROTOCOL)
	
	os.system('./telegram.sh "LDAs Done!"')
	
except Exception as e:
	print(repr(e))
	os.system('./telegram.sh "On ' + str(k) + ' Error:' + repr(e) + '"')

