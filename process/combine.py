#####################################################
#Must run in Python 2.7 because of encoding issues
######################################################

import pandas as pd
import os
from datasketch import MinHash, MinHashLSH
from nltk import ngrams

FILES_DIR = "C://Git/mine-food-security/data/"

#Scopus articles

SCOPUS_DIR = FILES_DIR + 'abstracts/'
KW_DIR = FILES_DIR + 'keywords/'

scopus1 = pd.read_csv(FILES_DIR + "scopus.csv")
scopus2 = pd.read_csv(FILES_DIR + "scopus_1.csv")

scopus = pd.concat([scopus1, scopus2]).reset_index()

scopus = scopus[["Title", "Authors", "Year", "DOI", "Source title", "EID", "Cited by", "Document Type"]]

body_files = os.listdir(SCOPUS_DIR)
body_missing = []

kw_files = os.listdir(KW_DIR)
kw_missing = []

for i in range(0, len(scopus[["EID"]])):
    eid = scopus.loc[scopus.index[i], "EID"]

    #Get body
    if eid in body_files:
        f = open(SCOPUS_DIR + eid, "r")
        abstract = f.read().rstrip('\n')
        #remove copywrite
        abstract = abstract[ : abstract.find('©')]
        scopus.loc[i, "text"] = abstract
    else:
        body_missing.append(eid)
        
    #Get keywords
    if eid in kw_files:
        f = open(KW_DIR + eid, "r")
        keywords = f.read().rstrip('\n')
        scopus.loc[i, "keywords"] = keywords
    else:
        body_missing.append(eid)

scopus = scopus.rename(index=str, columns={"Cited by": "CitationCount", "Source title": "Source", "Document Type": "Type"})

#Remove missing abstracts
scopus = scopus.loc[scopus['text'] != '[No abstract available']
scopus = scopus.loc[scopus['text'] != '']
scopus = scopus.loc[scopus['text'] != 'Abstract available from the publisher']
scopus = scopus.loc[~pd.isnull(scopus['text'])]

#Filter short abstracts:
scopus = scopus.loc[scopus['text'].apply(len) >= 250]

#Filter based on document type
scopus = scopus.loc[scopus['Type'].apply(lambda x: x not in ['Erratum', 'Retracted'])]

##Use Locality-Sensitive Hashing to find and remove near-duplicates
#https://stackoverflow.com/questions/25114338/approximate-string-matching-using-lsh
threshold = 0.75
ngram = 3

lsh = MinHashLSH(threshold=0.5, num_perm=128)

scopus = scopus.reset_index(drop=True)

minhashes = {}
for c, i in enumerate(scopus['text']):
    minhash = MinHash(num_perm=128)
    for d in ngrams(i.split(" "), 3):
        minhash.update("".join(d))
    lsh.insert(c, minhash)
    minhashes[c] = minhash

def jaccard(a, b):
    c = a.intersection(b)
    return float(len(c)) / (len(a) + len(b) - len(c))

for i in xrange(len(minhashes.keys())):
    result = lsh.query(minhashes[i])
    a = scopus['text'].loc[i]
    for r in result:
        if r in scopus.index:
            b = scopus['text'].loc[r]
        else:
            pass
        
        d = jaccard(set(ngrams(a.split(" "), 3)), set(ngrams(b.split(" "), 3)))
        
        if (d > 0.3) & (i > r):
            #print i, "\t", r, "\tDist:", d, "\n", a[:400], "\n", b[:400], "\n\n\n"
            
            #Only delete if i > r.  This keeps one of every duplicate and avoids counting i==r as a duplicate
            if r in scopus.index:
                scopus = scopus.drop(r)

scopus.to_csv('G://My Drive/mine-food-security/abstracts.csv', index=False)






























