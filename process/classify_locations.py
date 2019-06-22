import pandas as pd
import os
import ast
from collections import Counter, defaultdict

os.chdir('G://My Drive/mine-food-security')

abs_loc = pd.read_csv("Locations2.csv")
abs_new = pd.read_csv("abstracts_final.csv")

abs_loc = abs_loc.loc[abs_loc.EID.isin(abs_new.EID), ]

loc_con = pd.read_csv("all_locations_processed_manual2_continents.csv")

def getContinents(dict_str):
    if pd.isnull(dict_str):
        return([])
    
    dict_str = dict_str.replace('b\'{', '{').replace('}\'', '}')
    
    d = ast.literal_eval(dict_str)
    res = []
    for loc in d:
        continent = loc_con.loc[loc_con['location']==loc, 'continent'].to_string(index=False)
        for i in range(d[loc]):
            res.append(continent)
    return(res)

def getCountries(dict_str):
    if pd.isnull(dict_str):
        return([])
    
    dict_str = dict_str.replace('b\'{', '{').replace('}\'', '}')
    
    d = ast.literal_eval(dict_str)
    res = []
    for loc in d:
        country = loc_con.loc[loc_con['location']==loc, 'country'].to_string(index=False)
        if country in ['NaN', 'Series([], )']:
            continue
        for i in range(d[loc]):
            res.append(country)
    return(res)

for i in abs_loc.index:
    if i < 9087:
        continue
    
    print(i)
    
    #############################
    #First do Continents
    ##############################
    
    abs_con = getContinents(abs_loc.loc[i]['loc_abstract'])
    key_con = getContinents(abs_loc.loc[i]['loc_keywords'])
    tit_con = getContinents(abs_loc.loc[i]['loc_title'])
    
    unique = Counter(abs_con + key_con + tit_con)
    
    #If no toponyms, aspatial
    if len(unique) == 0:
        verdict = "No Regional Focus"
    
    #If they all agree, easy
    elif len(unique) == 1:
        verdict = list(unique.keys())[0]
    
    #If there are two unique values
    elif len(unique) == 2:
        
        #If the title and the keys do not have a duplicate and they have a value 
        if (len(set(tit_con)) <= 2) & (len(set(key_con)) <= 2) & (len(set(tit_con + key_con)) == 1):
            
            #use the value from the title and the keys
             verdict = list(set(tit_con + key_con))[0]
            
        #If they have different counts, go with the bigger count
        elif list(unique.values())[0] != list(unique.values())[1]:
            if list(unique.values())[0] > list(unique.values())[1]:
                verdict = list(unique.keys())[0]
            else:
                verdict = list(unique.keys())[1]
                
        #If they have equal counts and one is global, go with the other
        elif "No Regional Focus" in list(unique.keys()):
            tmp = list(unique.keys())
            tmp.remove('No Regional Focus')
            verdict = tmp[0]     
        
        #If they have equal counts and one is first world, go with the other    
        elif "First World" in list(unique.keys()):
            tmp = list(unique.keys())
            tmp.remove('First World')
            verdict = tmp[0]
        
        #Else Global
        else:
            verdict = "No Regional Focus"
    
    #If there are more than 2 unique values
    else:
        
        #If the title and the keys do not have a duplicate and they have a value 
        if (len(set(tit_con)) <= 2) & (len(set(key_con)) <= 2) & (len(set(tit_con + key_con)) == 1):
            
            #use the value from the title and the keys
             verdict = list(set(tit_con + key_con))[0]
            
        #If any one continent is greater than half of the other continents
        elif max(list(unique.values()))*2 > sum(unique.values()):
            
            #use that continent
            verdict = max(unique, key=unique.get)
    
        #else it's global
        else:
            verdict = "No Regional Focus"
    
    abs_loc.loc[i, 'con_abstact'] = str(dict(Counter(abs_con)))
    abs_loc.loc[i, 'con_title'] = str(dict(Counter(tit_con)))
    abs_loc.loc[i, 'con_keywords'] = str(dict(Counter(key_con)))
    abs_loc.loc[i, 'con_verdict'] = verdict
    
    ###########################
    #Do Countries
    #
    #By simple Majority
    ############################
    
    abs_cty = getCountries(abs_loc.loc[i]['loc_abstract'])
    key_cty = getCountries(abs_loc.loc[i]['loc_keywords'])
    tit_cty = getCountries(abs_loc.loc[i]['loc_title'])
    
    all_cty = tit_cty + key_cty + abs_cty
    
    if all_cty == []:
        continue
    
    loc_dict = defaultdict(int)
    for loc in all_cty:
        loc_dict[loc] += 1
    
    cty = max(loc_dict, key=loc_dict.get)
    
    if loc_dict[cty] > len(all_cty)/2.0:
        abs_loc.loc[i, 'cty_abstact'] = str(dict(Counter(abs_cty)))
        abs_loc.loc[i, 'cty_title'] = str(dict(Counter(tit_cty)))
        abs_loc.loc[i, 'cty_keywords'] = str(dict(Counter(key_cty)))
        abs_loc.loc[i, 'cty_verdict'] = cty
    

abs_loc.to_csv('Abstract_locations_classified.csv', index=False, encoding='utf-8')