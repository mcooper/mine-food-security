import requests
import json

#######################################
#Scope Available Docs
#######################################

#Read in API keys
f = open('C://Git/mine-food-security/api-keys', 'r').read()
keys = json.loads(f)

#Determine how many results there are
query = 'https://api.elsevier.com/content/search/scidir?query=tak({food security} OR {food insecurity})'

r = requests.get(query, 
                 headers={'X-ELS-APIKey': keys['elsevier']})

num_results = int(json.loads(r.text)['search-results']['opensearch:totalResults'])

#Paginate through and collect results
articles = []
for i in range(0, num_results, 100):
    print(i)
    
    r = requests.get(query + '&start=' + str(i) + '&count=100', 
                 headers={'X-ELS-APIKey': keys['elsevier']})
    
    articles = articles + json.loads(r.text)['search-results']['entry']

f = open('G://My Drive/mine-food-security/elsevier/elsevier_scope', 'w')
f.write(json.dumps(articles))

##############################################################
#Get individual articles, with text in body, and write
################################################################
query = 'https://api.elsevier.com/content/article/pii/'

missing = []
for a in articles:
    print(articles.index(a))
    
    pii = a['pii']
    r = requests.get(query + pii, headers={'X-ELS-APIKey': keys['elsevier']})
    
    if '</body>' not in r.text:
        missing.append(pii)
        
    f = open('G://My Drive/mine-food-security/elsevier/' + pii, 'wb')
    f.write(r.text.encode())
    f.close()