import pandas as pd
import requests as req
from xml.etree import ElementTree
from bs4 import BeautifulSoup
import os

def getContentURL(eid):
	docXMLDetailsURL = "https://api.elsevier.com/content/abstract/eid/{eid}"
	res = req.get(docXMLDetailsURL.format(eid = eid))
	root = ElementTree.fromstring(res.content)
	#dirty because of xmlns
	docContentURL = root.getchildren()[0].getchildren()[-1].attrib['href']
	return docContentURL

def getAbstract(docContentURL):
	html_doc = req.get(docContentURL).content
	soup = BeautifulSoup(html_doc, 'html.parser')
	abstract = soup.h3.find_next_siblings('p')[0].get_text()
	return abstract

def Abstract(eid):
	url = getContentURL(eid)
	abstract = getAbstract(url)
	return abstract
	

abstractPath = r'D:\Projects\textMining\data\abstracts'
df = pd.read_csv(r'D:\Projects\textMining\data\scopus.csv')
eid_list = list(df.EID)
#for restarting, check previous results
done = os.listdir(abstractPath)
eid_list = list(set(eid_list) - set(done))
#GO
for eid in eid_list:    
    try:
        abstract = Abstract(eid)
        with open(os.path.join(abstractPath,eid),'w') as f:
            f.write(abstract.encode('utf8'))
    except:
        with open(os.path.join(abstractPath,'errors'),'a') as f:
            f.write(eid+'\n')


