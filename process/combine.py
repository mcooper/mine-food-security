import pandas as pd
import os

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

#TODO: Filter short abstracts?
#      Filter based on document type
#      Filter potential duplicates/similar abstracts?

scopus.to_csv(FILES_DIR + 'abstracts.csv', index=False)