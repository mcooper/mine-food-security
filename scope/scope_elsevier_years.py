#Note: only works with Python 2

import os
import json

os.chdir('G://My Drive/mine-food-security/elsevier')

fs = os.listdir('.')

years = []
for f in fs:
    doc = open(f, 'r')
    string = doc.read();

    end = string.find('</prism:coverDisplayDate>')
    
    years.append(string[end - 4:end])
    
    doc.close()

import pandas as pd

df = pd.DataFrame({'year' : years})
df['year'].value_counts()