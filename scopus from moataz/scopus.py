import requests
import json
#https://dev.elsevier.com/documentation/ScopusSearchAPI.wadl

#######################################
#Scope Available Docs
#######################################

API_KEY = "fc6b5d177a50259fc522259653f30bf4"
WRITE_URL = r"D:\Projects\textMining\data"

#Determine how many results there are
query = 'https://api.elsevier.com/content/search/scopus?query=KEY({food security} OR {food insecurity})'

res = requests.get(query, headers={'X-ELS-APIKey': API_KEY})

#results = json.loads(r.text)
results = res.json()
print results

num_results = int(results[u'search-results'][u'opensearch:totalResults'])

#Paginate through and collect results
articles = []
for i in range(0, num_results, 50):
    print(i)
    
    #startIndex? opensearch:startIndex
    r = requests.get(query + '&start=' + str(i) + '&count=50', 
                 headers={'X-ELS-APIKey': API_KEY})
    
    articles = articles + json.loads(r.text)[u'search-results'][u'entry']

#f = open('G://My Drive/mine-food-security/scopus/scopus_scope', 'w')
#f.write(json.dumps(articles))

##############################################################
#Get individual articles, with text in body, and write
################################################################
query = 'https://api.elsevier.com/content/abstract/scopus_id/'

for a in articles:
    print(articles.index(a)/float(len(articles)))
    
    id = a[u'dc:identifier'].replace('SCOPUS_ID:', '')
    r = requests.get(query + id, headers={'X-ELS-APIKey': API_KEY})
    
    f = open(WRITE_URL + id, 'wb')
    f.write(r.text.encode())
    f.close()