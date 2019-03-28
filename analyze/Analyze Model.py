import pandas as pd
import os
import pickle
import numpy as np
import re

k = 28

os.chdir('G://My Drive/mine-food-security/')

abstracts = pd.read_csv('abstracts.csv')

with open("LDA-dictionary", "rb") as input_file:
    dictionary = pickle.load(input_file, encoding='latin1')

with open("LDA-corpus", "rb") as input_file:
    corpus = pickle.load(input_file, encoding='latin1')

with open("LDAmods/mod" + str(k), "rb") as input_file:
    mod = pickle.load(input_file, encoding='latin1')


topic_word_distrib = mod.state.get_lambda()

#Get top words for each topic
topic_words = mod.print_topics(num_topics=k, num_words=15)
wordranksdf = pd.DataFrame({})
for topic_number in range(0,k):
    #Get top 15 words
    for topic in topic_words:
        if topic[0] == topic_number:
            wordranks = re.sub(' \+ ', ', ', re.sub('.....\*', '', topic[1]))
    wordranksdf = wordranksdf.append(pd.DataFrame({"Topic_Number": topic_number, "TopWords": wordranks.encode('utf8')}, index=[0]))

wordranksdf.to_csv('mod' + str(k) + 'wordranks.csv', index=False)

doc_topic_list = []
for doc_topic in mod.get_document_topics(corpus):
    d = dict(doc_topic)
    t = tuple(d.get(ind, 0.) for ind in range(mod.num_topics))
    doc_topic_list.append(t)

doc_topic_distrib = np.array(doc_topic_list)

pd.DataFrame(doc_topic_distrib).to_csv('mod' + str(k) + 'doc_topic_distribution.csv')

abstract_example_df = pd.DataFrame({})
for i in range(0, k):
    max10_ind = doc_topic_distrib[:,i].argsort()[-10:][::-1].tolist()
    sel = abstracts.iloc[max10_ind]['text'].tolist()
    rowdict = {'k': i}
    for j in range(0, 10):
        rowdict[str(j)] = sel[j]
    tmp = pd.DataFrame(rowdict, index=[0])
    abstract_example_df = abstract_example_df.append(tmp)

abstract_example_df.to_csv('mod' + str(k) + 'topic_abstracts.csv', index=False)

#Get J-S Distance
from scipy.stats import entropy
from numpy.linalg import norm
import numpy as np
import math

def JSD(P, Q):
    _P = P / norm(P, ord=1)
    _Q = Q / norm(Q, ord=1)
    _M = 0.5 * (_P + _Q)
    return 0.5 * (entropy(_P, _M) + entropy(_Q, _M))

jsd_mat = np.empty([k, k])

for i in range(k):
    p = topic_word_distrib[i, :]
    for j in range(k):
        q = topic_word_distrib[j, :]
        jsd_mat[i, j] = math.sqrt(JSD(p, q))

#scale?
jsd_mat = jsd_mat - jsd_mat[np.nonzero(jsd_mat)].min()
jsd_mat = jsd_mat/jsd_mat.max()

pd.DataFrame(jsd_mat).to_csv('mod' + str(k) + 'jsd_mat.csv')

from sklearn.manifold import MDS

embedding = MDS(2, metric=False)

transformed = embedding.fit_transform(jsd_mat)

pd.DataFrame(transformed).to_csv('mod' + str(k) + 'transformed_coords_nonmetric.csv')

#import matplotlib.pyplot as plt

#fig, ax = plt.subplots()
#ax.scatter(transformed[:, 0], transformed[:, 1])

#for i, txt in enumerate(range(k)):
#    ax.annotate(txt, (transformed[i, 0], transformed[i, 1]))