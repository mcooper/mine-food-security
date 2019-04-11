import pandas as pd
import os
import json
from collections import defaultdict

FILES_DIR = "G://My Drive/mine-food-security/"

os.chdir(FILES_DIR)

#Read in abstract data and add words indicative of a global focus
global_words = ['globe', 'global', 'world', 'international', 'planet', 'countries']

abstracts = pd.read_csv('abstracts.csv')
abstracts = abstracts.fillna('')
files = os.listdir('C://Git/mine-food-security/data/entities/')
eids = list(set(map(lambda x: x[:x.rfind('-')], files)))

def process_file(filename):
    locations = defaultdict(int)
    entities = json.loads(open('C://Git/mine-food-security/data/entities/' + filename, 'rb').read())
    
    if "InvalidArgument" in entities:
        return {}
    
    for e in entities:
        if e['type'] == 'LOCATION':
            for m in e['mentions']:
                if m['type'] == 'PROPER':
                    locations[e['name'].lower()] += 1
                    all_locations[e['name'].lower()] += 1
                    
    return(locations)

#Get dicts of raw location names for each abstract from the entities file
data = []
all_locations = defaultdict(int)
for eid in eids:
    title = process_file(eid + '-title')
    abstract = process_file(eid + '-abstract')
    if eid + '-keywords' in files:
        keywords = process_file(eid + '-keywords')
    else:
        keywords = {}
    
    #Get global keywords
    sel = abstracts.loc[abstracts['EID']==eid, ]
    
    if len(sel.index)==0:
        continue
    
    title_txt = sel.iloc[0]['Title']
    kw_txt = sel.iloc[0]['keywords']
    abs_txt = sel.iloc[0]['text']
    
    for word in global_words:
        if word in title_txt:
            title[word] = title_txt.count(word)
        if word in kw_txt:
            keywords[word] = kw_txt.count(word)
        if word in abs_txt:
            abstract[word] = abs_txt.count(word)
    
    title = json.dumps(title, ensure_ascii=False).encode('utf8')
    keywords = json.dumps(keywords, ensure_ascii=False).encode('utf8')
    abstract = json.dumps(abstract, ensure_ascii=False).encode('utf8')
    
    temp = {'EID': eid, 'loc_title': title, 'loc_abstract': abstract, 'loc_keywords': keywords}
    
    data.append(temp)
    
    print(eids.index(eid))

df = pd.DataFrame(data)
df.to_csv(FILES_DIR + "Locations.csv", index=False)

f = open(FILES_DIR + 'All_Locations.csv', 'wb+')
f.write('location,count\n')
for d in all_locations:
    if isinstance(d, int):
        f.write('"' + str(d) + '",' + str(all_locations[d]) + '\n')
    else:
        f.write('"' + d.encode('utf-8') + '",' + str(all_locations[d]) + '\n')
f.close()