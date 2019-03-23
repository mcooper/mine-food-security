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
import numpy as np
from tmtoolkit.topicmod import evaluate
from gensim.models import CoherenceModel

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
                         "objective", "objectives", "result", "conculsion",
                         "results", "conclusions", "purpose", "purposes", 
                         "methods", "method", "methodology", "approaches",
                         "data", "introduction", "approach", "result",
                         "estimate", "estimation", "among", "also", "review",
                         "make", "first", "significant", "significance", "find",
                         "finding", "findings", "found", "may", "might", "can", 
                         "could", "suggest", "suggests", "suggestion", "survey",
                         "suggestions", "surveys", "three", "two", "one", "four", 
                         "five", "six", "seven", "eight", "nine", "ten", "present",
                         "presents", "presenting", "presented", "presenter", "presentation",
                         "however", "futhermore", "moreover", "within", "main", 
                         "show", "shows", "reserach", "assess", "assessed", "assessment", "examine",
                         "examined", "examines", "report", "reported", "reporting",
                         "like", "include", "including", "includes", 
                         "increased", "increasing", "increases", "higher", "lower",
                         "raises", "lowers", "develop", "develops", "developed",
                         "development", "differ", "differs", "different", "product",
                         "production", "use"]

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

bigram = Phrases(texts, min_count=15)
for idx in range(len(texts)):
    for token in bigram[texts[idx]]:
        if '_' in token:
            # Token is a bigram, add to document.
            texts[idx].append(token)

dictionary = corpora.Dictionary(texts)
dictionary.filter_extremes(no_below=10, no_above=0.3)
corpus = [dictionary.doc2bow(text) for text in texts]

with open('LDA-dictionary', 'wb') as handle:
    pickle.dump(dictionary, handle, protocol=pickle.HIGHEST_PROTOCOL)

with open('LDA-corpus', 'wb') as handle:
    pickle.dump(corpus, handle, protocol=pickle.HIGHEST_PROTOCOL)

with open('LDA-texts', 'wb') as handle:
    pickle.dump(texts, handle, protocol=pickle.HIGHEST_PROTOCOL)

ks = list(range(2, 40, 4)) + list(range(40, 55, 1)) + list(range(55, 100, 5)) + list(range(100, 150, 10)) + list(range(150, 201, 25)) 

#################################
#Make Models
##############################

ks2 = list(range(6, 40, 1))
for k in ks2:
    if k in ks:
        ks2.remove(k)

try:
	for k in ks2:
		print(k)
		
		ldamodel = models.ldamulticore.LdaMulticore(corpus, num_topics=k, id2word = dictionary, passes=40, workers=3)
		
		with open('LDAmods/mod' + str(k), 'wb') as handle:
			pickle.dump(ldamodel, handle, protocol=pickle.HIGHEST_PROTOCOL)
	
	os.system('./telegram.sh "LDAs Done!"')
	
except Exception as e:
	print(repr(e))
	os.system('./telegram.sh "On ' + str(k) + ' Error:' + repr(e) + '"')

	
#################################
#Evaluate Models
##############################
#Pickle wont re-load corpus the same, for some reason, so just re-evaluate in same environment

try:
	#resultsdf = pd.DataFrame({})
	for k in ks2:
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

resultsdf.to_csv('LDAmod_evaluation.csv', index=False)

