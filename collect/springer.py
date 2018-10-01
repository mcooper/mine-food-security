import requests
import json


#######################################
#Scope Available Docs
#######################################

#Read in API keys
f = open('C://Git/mine-food-security/api-keys', 'r').read()
keys = json.loads(f)

#Determine how many results there are
query = 'http://api.springernature.com/metadata/json?q=' + '(keyword:food security OR keyword:food insecurity OR title:"food security" OR title:"food insecurity)"' + '&api_key=' + keys['springer']

r = requests.get(query)

num_results = int(json.loads(r.text)['result'][0]['total'])

#Paginate through and collect results
articles = []
for i in range(0, num_results, 50):
    print(i)
    print(len(articles))
    
    r = requests.get(query + '&s=' + str(i) + '&p=100')
    
    articles = articles + json.loads(r.text)['records']

f = open('G://My Drive/mine-food-security/springer/springer_scope', 'w')
f.write(json.dumps(articles))


##############################################################
#Get individual articles, with text in body, and write
##############################################################

#It looks like it is possible to only get full text for open access articles. Grrr..