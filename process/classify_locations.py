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
        
    d = ast.literal_eval(dict_str)
    res = []
    for loc in d:
        if loc in loc_con['location'].tolist():
            continent = loc_con.loc[loc_con['location']==loc, 'Selected Continent'].to_string(index=False)
            for i in range(d[loc]):
                res.append(continent)
    return(res)

for i in abs_loc.index:
    abs_c = getContinents(abs_loc.loc[i]['loc_abstract'])
    key_c = getContinents(abs_loc.loc[i]['loc_keywords'])
    tit_c = getContinents(abs_loc.loc[i]['loc_title'])
    
    unique = Counter(abs_c + key_c + tit_c)
    
    #If no toponyms, aspatial
    if len(unique) == 0:
        verdict = "Aspatial"
    
    #If they all agree, easy
    elif len(unique) == 1:
        verdict = list(unique.keys())[0]
    
    #If there are two unique values
    elif len(unique) == 2:
        
        #If the title and the keys do not have a duplicate and they have a value 
        if (len(set(tit_c)) <= 2) & (len(set(key_c)) <= 2) & (len(set(tit_c + key_c)) == 1):
            
            #use the value from the title and the keys
             verdict = list(set(tit_c + key_c))[0]
            
        #If they have different counts, go with the bigger count
        elif list(unique.values())[0] != list(unique.values())[1]:
            if list(unique.values())[0] > list(unique.values())[1]:
                verdict = list(unique.keys())[0]
            else:
                verdict = list(unique.keys())[1]
    
        #If they have equal counts and one is first world, go with the other    
        elif "First World" in list(unique.keys()):
            tmp = list(unique.keys())
            tmp.remove('First World')
            verdict = tmp[0]
        
        #Else Global
        else:
            verdict = "Global"
    
    #If there are more than 2 unique values
    else:
        
        #If the title and the keys do not have a duplicate and they have a value 
        if (len(set(tit_c)) <= 2) & (len(set(key_c)) <= 2) & (len(set(tit_c + key_c)) == 1):
            
            #use the value from the title and the keys
             verdict = list(set(tit_c + key_c))[0]
            
        #If any one continent is greater than half of the other continents
        elif max(list(unique.values()))*2 > sum(unique.values()):
            
            #use that continent
            verdict = max(unique, key=unique.get)
    
        #else it's global
        else:
            verdict = "Global"
    
    abs_loc.loc[i, 'con_abstact'] = str(dict(Counter(abs_c)))
    abs_loc.loc[i, 'con_title'] = str(dict(Counter(tit_c)))
    abs_loc.loc[i, 'con_keywords'] = str(dict(Counter(key_c)))
    abs_loc.loc[i, 'verdict'] = verdict

abs_loc.to_csv('Locations_classified.csv', index=False)