# -*- coding: utf-8 -*-
"""
Created on Wed Mar 20 17:59:07 2019

@author: matt
"""

token2id = dictionary.token2id
id2token = {}

for token in token2id:
    key = token
    value = token2id[token]
    id2token[value] = key

newdict = {}
for d in dfs:
    if dfs[d] > 25738/10.0:
        string = id2token[d]
        value = dfs[d]/25738
        newdict[string] = value