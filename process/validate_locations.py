import pandas as pd
import os

os.chdir('G://My Drive/mine-food-security')

loc = pd.read_csv('Abstract_locations_classified.csv')
validation = pd.read_csv('Sample_Validation_Locations.csv')

loc = loc[['EID', 'con_verdict', 'cty_verdict']]
validation = validation[['EID', 'Continent', 'Country']]

comb = validation.merge(loc, how='inner', on='EID')

#Continent Analysis
print(pd.crosstab(comb['con_verdict'], comb['Continent']).to_string())

#Continent          Africa  Asia  First World  LAC  No Regional Focus
#verdict                                                             
#Africa                 64     0            0    0                  2
#Asia                    0    66            0    0                  0
#First World             0     1           35    1                  2
#LAC                     0     0            0   10                  0
#No Regional Focus       7    10           10    1                 91

#79.666 correct

cty_comb = comb[comb.cty_verdict.notnull() | comb.Country.notnull()]

comb['cty'] = comb['cty_verdict'] == comb['Country']

#Continent          Africa  Asia  First World  LAC  No Regional Focus
#verdict                                                             
#Africa                 64     0            0    0                  2
#Asia                    0    66            0    0                  0
#First World             0     1           35    1                  2
#LAC                     0     0            0   10                  0
#No Regional Focus       7    10           10    1                 91

#79.666 correct



#If we exclude those classified as aspatial or world
sel = comb.loc[comb['verdict'].isin(['Africa', 'Asia', 'First World', 'LAC'])]
pd.crosstab(sel['verdict'], sel['Continent'])

#Continent    Africa  Asia  First World  LAC  None  World
#verdict                                                 
#Africa           65     0            0    0     1      4
#Asia              0    66            1    0     0      3
#First World       0     0           35    0     3      3
#LAC               0     0            1   13     0      1

#92% correct