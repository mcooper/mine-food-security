import pandas as pd
import os

os.chdir('G://My Drive/mine-food-security')

loc = pd.read_csv('Locations_classified.csv')
validation = pd.read_csv('Sample_Validation_Locations.csv')

loc = loc[['EID', 'verdict']]
validation = validation[['EID', 'Continent']]

comb = validation.merge(loc, how='inner', on='EID')

pd.crosstab(comb['verdict'], comb['Continent'])

#Continent    Africa  Asia  First World  LAC  None  World
#verdict                                                 
#Africa           65     0            0    0     1      4
#Asia              0    66            1    0     0      3
#Aspatial          1     4            8    1    55     30
#First World       0     0           35    0     3      3
#Global            0     0            0    0     0      5
#LAC               0     0            1   13     0      1

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