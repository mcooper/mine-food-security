import pandas as pd
import numpy as np
import os
import json
from collections import defaultdict

FILES_DIR = "C://Git/mine-food-security/data/"

os.chdir(FILES_DIR)

data = []

files = os.listdir('entities')
eids = list(set(map(lambda x: x[:x.rfind('-')], files)))

def process_file(filename):
    locations = defaultdict(int)
    entities = json.loads(open('entities/' + filename, 'rb').read())
    
    if "InvalidArgument" in entities:
        return np.nan
    
    for e in entities:
        if e['type'] == 'LOCATION':
            for m in e['mentions']:
                if m['type'] == 'PROPER':
                    locations[e['name'].lower()] += 1
                    all_locations[e['name'].lower()] += 1
                    
    return(json.dumps(locations, ensure_ascii=False).encode('utf8'))

all_locations = defaultdict(int)
for eid in eids:
    title = process_file(eid + '-title')
    abstract = process_file(eid + '-abstract')
    if eid + '-keywords' in files:
        keywords = process_file(eid + '-keywords')
    else:
        keywords = np.nan
        
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