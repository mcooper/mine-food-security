
import pandas as pd
import os


#For each document, get
#   year
#   journal
#   title
#   text
#   doi


FILES_DIR = "G://My Drive/mine-food-security/"

#Scopus articles

SCOPUS_DIR = FILES_DIR + 'abstracts/abstracts/'

scopus1 = pd.read_csv(FILES_DIR + "scopus.csv")
scopus2 = pd.read_csv(FILES_DIR + "scopus_1.csv")

scopus = pd.concat([scopus1, scopus2]).reset_index()

scopus = scopus[["Title", "Year", "DOI", "Source title", "EID"]]

files = os.listdir(SCOPUS_DIR)
missing = []
for i in range(0, len(scopus[["EID"]])):
    eid = scopus.loc[scopus.index[i], "EID"]

    if eid in files:
        f = open(SCOPUS_DIR + eid, "r")
        
        abstract = f.read().rstrip('\n')
        
        #remove copywrite
        abstract = abstract[ : abstract.find('©')]
        
        scopus.loc[i, "text"] = abstract
    else:
        missing.append(eid)

scopus['source'] = "scopus"
scopus.rename(index=str, columns={"Source title": "Journal"})


import json
from collections import defaultdict
import numpy as np

def load_location(filepath):
    f = open(filepath).read().decode("utf-8").split('\n')
    dat = []
    for loc in f:
        dat.append(json.loads(loc))
    return(dat)

def get_country_dict(text, countries):
    if type(text)!=str:
        return(np.NaN)
    texte = text.decode('utf-8')
    dd = defaultdict(int)
    for c in countries:
        for a in set(c['aliases']):
            if a in texte:
                dd[c['country']] += texte.count(a)
    return(dict(dd))

countries = load_location("C://Git/mine-food-security/locations/countries.json")

scopus['country'] = scopus['text'].apply(lambda x: get_country_dict(x, countries))

scopus.to_csv('G://My Drive/mine-food-security/abstracts.csv', index=False)






