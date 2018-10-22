# -*- coding: utf-8 -*-
"""
Created on Fri Oct 19 13:31:36 2018

@author: matt
"""

import pandas as pd
import json
import os
import xml.etree.ElementTree

FILES_DIR = 'G://My Drive/mine-food-security'

#Get crossref DOIs
os.chdir(FILES_DIR + "/crossref")

crossref = []
for f in os.listdir():
    file = open(f, 'rb')
    data = json.loads(file.read())
    crossref.append(data["DOI"])

#Get elsevier DOIs
os.chdir(FILES_DIR + "/elsevier")

elsevier = []
for f in os.listdir()[1:]:
    doi = xml.etree.ElementTree.parse(f).getroot()[0][3].text
    elsevier.append(doi)

#Get springer DOIs
os.chdir(FILES_DIR + '/springer')
file = open('springer_scope', 'rb')
data = json.loads(file.read())

springer = []
for d in data:
    springer.append(d['doi'])

#Get scopus DOIs
os.chdir(FILES_DIR + '/scopus')

sc0 = pd.read_csv('scopus.csv')
sc_doi_0 = sc0["DOI"].dropna().tolist()

sc1 = pd.read_csv('scopus_1.csv')
sc_doi_1 = sc1["DOI"].dropna().tolist()

scopus = sc_doi_0 + sc_doi_1

#Scope
len([doi for doi in elsevier if doi in scopus])/len(elsevier)

len([doi for doi in springer if doi in scopus])/len(springer)

len([doi for doi in crossref if doi in scopus])/len(crossref)















