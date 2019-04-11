import pandas as pd
import os
import ast
from collections import Counter

os.chdir('G://My Drive/mine-food-security')

abs_loc = pd.read_csv("Locations.csv")
loc_con = pd.read_csv("all_locations_processed_manual_onlygood.csv")

def getContinents(dict_str):
    if pd.isnull(dict_str):
        return([])
    
    dict_str = dict_str.replace('b\'{', '{').replace('}\'', '}')
    
    d = ast.literal_eval(dict_str)
    res = []
    for loc in d:
        if loc in ['globe', 'global', 'world', 'international', 'planet', 'countries']:
            res.append('No Regional Focus')
        if loc in loc_con['location'].tolist():
            continent = loc_con.loc[loc_con['location']==loc, 'Selected Continent'].to_string(index=False)
            for i in range(d[loc]):
                res.append(continent)
    return(res)

alldf = pd.DataFrame()
for i in abs_loc.index:
    print(i)
    
    abs_c = Counter(getContinents(abs_loc.loc[i]['loc_abstract']))
    key_c = Counter(getContinents(abs_loc.loc[i]['loc_keywords']))
    tit_c = Counter(getContinents(abs_loc.loc[i]['loc_title']))
    
    abs = {'abs-' + k: v for k, v in abs_c.items()}
    key = {'key-' + k: v for k, v in key_c.items()}
    tit = {'tit-' + k: v for k, v in tit_c.items()}
    
    all_d = {**abs, **key, **tit}
    
    all_d['EID'] = abs_loc.loc[i, 'EID']
    
    alldf = alldf.append(pd.DataFrame(all_d, index=[0]))

alldf = alldf.fillna(0)

train = pd.read_csv('Sample_Validation_Locations.csv')

comb = pd.merge(train, alldf, how='inner', on='EID')

import random

train = random.sample(range(300), 200)
valid = [x for x in range(300) if x not in train]

y_train = comb.iloc[train]['Continent']
X_train = comb.iloc[train][['abs-Africa', 'abs-Asia',
       'abs-First World', 'abs-LAC', 'abs-No Regional Focus', 'key-Africa',
       'key-Asia', 'key-First World', 'key-LAC', 'key-No Regional Focus',
       'tit-Africa', 'tit-Asia', 'tit-First World', 'tit-LAC',
       'tit-No Regional Focus']]

X_valid = comb.iloc[valid][['abs-Africa', 'abs-Asia',
       'abs-First World', 'abs-LAC', 'abs-No Regional Focus', 'key-Africa',
       'key-Asia', 'key-First World', 'key-LAC', 'key-No Regional Focus',
       'tit-Africa', 'tit-Asia', 'tit-First World', 'tit-LAC',
       'tit-No Regional Focus']]

from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import cross_val_score

mod = DecisionTreeClassifier()

y = comb['Continent']
X = comb[['abs-Africa', 'abs-Asia',
       'abs-First World', 'abs-LAC', 'abs-No Regional Focus', 'key-Africa',
       'key-Asia', 'key-First World', 'key-LAC', 'key-No Regional Focus',
       'tit-Africa', 'tit-Asia', 'tit-First World', 'tit-LAC',
       'tit-No Regional Focus']]

cross_val_score(mod, X, y, cv=10).mean()

fit = mod.fit(X, y)

alldf['Continent'] = fit.predict(alldf[['abs-Africa', 'abs-Asia',
       'abs-First World', 'abs-LAC', 'abs-No Regional Focus', 'key-Africa',
       'key-Asia', 'key-First World', 'key-LAC', 'key-No Regional Focus',
       'tit-Africa', 'tit-Asia', 'tit-First World', 'tit-LAC',
       'tit-No Regional Focus']])

final = alldf[['EID', 'Continent']]

final.to_csv('Locations_classified_decisiontree.csv', index=False)