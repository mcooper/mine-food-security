# -*- coding: utf-8 -*-
"""
Created on Mon Oct 15 12:39:12 2018

@author: matt
"""


from crossref.restful import Works, Etiquette
import json

etq = Etiquette('Mining Food Security', 'v1.0', 'mcooper.github.io', 'mattcoop@terpmail.umd.edu')

works = Works(etiquette=etq)

w1 = works.query(title='food security insecurity').filter(has_abstract="true")

for item in w1:
    if "food security" in item['title'][0].lower() or "food insecurity" in item['title'][0].lower():
        f = open("G://My Drive/mine-food-security/crossref/" + item["DOI"].replace('/', '_'), 'wb')
        f.write(json.dumps(item))
        f.close()