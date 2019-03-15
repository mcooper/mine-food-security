#Latent Dirichlet Allocation
#Great documentation here: https://rstudio-pubs-static.s3.amazonaws.com/79360_850b2a69980c4488b1db95987a24867a.html

import pandas as pd
from nltk.tokenize import RegexpTokenizer
import textmining
from nltk.stem.snowball import SnowballStemmer
from gensim import corpora, models
import os
import pickle
from tmtoolkit.topicmod import evaluate
from gensim.models import CoherenceModel
import numpy as np


#os.chdir('C://Git/mine-food-security/data/')

data = pd.read_csv('abstracts.csv', encoding='utf-8')
abstracts = data['text'].tolist()

tdm = textmining.TermDocumentMatrix()

tokenizer = RegexpTokenizer(r'\w+')
stopwords = textmining.read_stopwords()

#Get rid of small numbers
stopwords = list(stopwords) + list(map(str, range(100)))

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

ks = list(range(10, 50)) + list(range(50, 100, 5)) + list(range(100, 140, 10))

try:
    resultsdf = pd.DataFrame({})
    for k in ks:
        
        with open("LDAmods/mod" + str(k), "rb") as input_file:
             mod = pickle.load(input_file, encoding='latin1')
             
        #Cao Juan 2009
        caojuan = evaluate.metric_cao_juan_2009(mod.state.get_lambda())
        
        # Compute Perplexity
        perplexity = mod.log_perplexity(corpus)  # a measure of how good the model is. lower the better.
        
        # Compute Coherence Score Want the highest value without flattening out
        coherence_model_lda = CoherenceModel(model=mod, texts=texts, dictionary=dictionary, coherence='c_v')
        coherence_lda = coherence_model_lda.get_coherence()
        
        #Arun et al
        topic_word_distrib = mod.state.get_lambda()
        
        doc_topic_list = []
        for doc_topic in mod.get_document_topics(corpus):
            d = dict(doc_topic)
            t = tuple(d.get(ind, 0.) for ind in range(mod.num_topics))
            doc_topic_list.append(t)
        doc_topic_distrib = np.array(doc_topic_list)
        
        doc_lengths = np.array(list(map(len, texts)))
         
        arun = evaluate.metric_arun_2010(mod.state.get_lambda(), doc_topic_distrib, doc_lengths)
        
        tmpdf = pd.DataFrame({'caojuan': caojuan, 'perplexity': perplexity, 'coherence': coherence_lda,
                              'arun': arun, 'k': k}, index=[0])
        
        resultsdf = resultsdf.append(tmpdf)
        
        print(k)
    os.system('./telegram.sh "Done with LDA mod evaluation"')
    
except Exception as ex:
    print(ex)
    os.system('./telegram.sh "Error in LDA evaluation"')





     