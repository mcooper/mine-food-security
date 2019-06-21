import os
import googlemaps
import pandas as pd
import json
import unicodedata
import io

FILES_DIR = "G://My Drive/mine-food-security/"
OUT_DIR = u"C://Users/matt/mine-food-security/data/locations/"

data = pd.read_csv(FILES_DIR + 'All_Locations2.csv')

api = json.loads(open("C://Users/matt/mine-food-security/maps_apikeys.json", "r").read())

gmaps = googlemaps.Client(key=api['maps_api'])

invalid = []
for loc in data['location']:
    res = gmaps.geocode(loc)
    try:
        f = open(OUT_DIR + unicode(loc, 'utf-8'), 'wb+')
        f.write(json.dumps(res, ensure_ascii=False).encode('utf-8'))
        f.close()
    except:
        invalid.append(loc)

files = [unicodedata.normalize('NFC', f) for f in os.listdir(OUT_DIR)]

for loc in files:
    out = io.open(OUT_DIR + loc, 'rb+').read()
    
    if out == '':
        continue
        print(u'No JSON on ' + loc)
    
    res = json.loads(out)
    
    if res == []:
        continue
        print(u'Empty JSON on ' + loc)
    
    #Note for cases where there are multiple returns, just take one    
    res = res[0]
    
    form_address = res['formatted_address']
    data.loc[data.location==loc, 'formatted_address'] = form_address
    
    coords_location_type = res['geometry']['location_type']
    data.loc[data.location==loc, 'coords_location_type'] = coords_location_type
    
    location_types = ', '.join(res['types'])
    data.loc[data.location==loc, 'location_types'] = location_types
    
    latitude = res['geometry']['location']['lat']
    data.loc[data.location==loc, 'latitude'] = latitude
    
    longitude = res['geometry']['location']['lng']
    data.loc[data.location==loc, 'longitude'] = longitude
    
    country_sel = [obj['long_name'] for obj in res['address_components'] if obj['types'][0] == "country"]
    if len(country_sel) > 0:
        country = country_sel[0]
        data.loc[data.location==loc, 'country'] = country
    
    continent_sel = [obj['long_name'] for obj in res['address_components'] if obj['types'][0] == "continent"]
    if len(continent_sel) > 0:
        continent = continent_sel[0]
        data.loc[data.location==loc, 'continent'] = continent
    
    if len(continent_sel) > 0 & len(continent_sel) > 0:
        print(loc)
    
data.to_csv(FILES_DIR + "all_locations_processed2.csv", index=False, encoding='utf-8')
