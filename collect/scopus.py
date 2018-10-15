import requests
import json

#######################################
#Scope Available Docs
#######################################

API_KEY = ""
WRITE_URL = ""

#Determine how many results there are
query = 'https://api.elsevier.com/content/search/scopus?query=KEY({food security} OR {food insecurity})'

r = requests.get(query, headers={'X-ELS-APIKey': API_KEY})

results = json.loads(r.text)

num_results = int(results['search-results']['opensearch:totalResults'])

#Paginate through and collect results
articles = []
for i in range(0, num_results, 50):
    print(i)
    
    r = requests.get(query + '&start=' + str(i) + '&count=50', 
                 headers={'X-ELS-APIKey': API_KEY})
    
    articles = articles + json.loads(r.text)['search-results']['entry']

#f = open('G://My Drive/mine-food-security/scopus/scopus_scope', 'w')
#f.write(json.dumps(articles))

##############################################################
#Get individual articles, with text in body, and write
################################################################
query = 'https://api.elsevier.com/content/abstract/scopus_id/'

for a in articles:
    print(articles.index(a)/float(len(articles)))
    
    id = a['dc:identifier'].replace('SCOPUS_ID:', '')
    r = requests.get(query + id, headers={'X-ELS-APIKey': API_KEY})
    
    f = open(WRITE_URL + id, 'wb')
    f.write(r.text.encode())
    f.close()