import pandas as pd
import os
import json
from collections import defaultdict

FILES_DIR = "C://Git/mine-food-security/data/"

os.chdir(FILES_DIR)

data = []

for eid in os.listdir('entities'):
    locations = defaultdict(int)
    entities = json.loads(open('entities/' + eid, 'rb').read())
    for e in entities:
        if e['type'] == 'LOCATION':
            for m in e['mentions']:
                if m['type'] == 'PROPER':
                    locations[e['name']] += 1
    
    temp = {'EID': eid, 'Locations': json.dumps(locations)}
    
    data.append(temp)

df = pd.DataFrame(data)

df.to_csv(FILES_DIR + "Locations.csv", index=False)