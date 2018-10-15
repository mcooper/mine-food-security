# -*- coding: utf-8 -*-
"""
Created on Mon Oct 15 14:17:14 2018

@author: matt
"""

from wos import WosClient
import wos.utils
import json

f = open('C://Git/mine-food-security/api-keys', 'r').read()
keys = json.loads(f)

client = WosClient() #keys["wos"]["username"], keys["wos"]["password"])

client.connect()

out = wos.utils.query(client, 'AU=Knuth Donald')