#Latent Dirichlet Allocation
#Great documentation here: https://rstudio-pubs-static.s3.amazonaws.com/79360_850b2a69980c4488b1db95987a24867a.html

import pandas as pd
from gensim import corpora
import os
import pickle
import numpy as np
from tmtoolkit.topicmod import evaluate
from gensim.models import CoherenceModel

with open("LDA-dictionary", "rb") as input_file:
    dictionary = pickle.load(input_file, encoding='latin1')

with open("LDA-corpus", "rb") as input_file:
    corpus = pickle.load(input_file, encoding='latin1')
    
with open("LDA-texts", "rb") as input_file:
    texts = pickle.load(input_file, encoding='latin1')


dictionary = corpora.Dictionary(texts)
dictionary.filter_extremes(no_below=10, no_above=0.5)
corpus = [dictionary.doc2bow(text) for text in texts]


originalks = list(range(2, 50, 3)) + list(range(50, 100, 5)) + list(range(100, 150, 10)) + list(range(150, 201, 25)) 

newks = list(range(35, 50))

ks = []
for k in newks:
    if k not in originalks:
        ks.append(k)

try:
    resultsdf = pd.DataFrame({})
    for k in originalks + newks:
        
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
            
        tmpdf = pd.DataFrame({'caojuan': caojuan, 'perplexity': perplexity, 'coherence': coherence_lda, 'arun': arun, 'k': k}, index=[0])
        
        resultsdf = resultsdf.append(tmpdf)
                
        print(k)
    os.system('./telegram.sh "Done with LDA mod evaluation"')
    
except Exception as ex:
    print(ex)
    os.system('./telegram.sh "Error in LDA evaluation"')





     