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

def getContentSoup(docContentURL):
    html_doc = req.get(docContentURL).content
    soup = BeautifulSoup(html_doc, 'html.parser')
    return soup

def getAbstract(soup):    
    #abstract = soup.h3.find_next_siblings('p')[0].get_text()
    abstract = soup.find("section",{"id":"abstractSection"}).p.get_text()
    return abstract

def getAuthorKeywords(soup):    
    try:
        keywords = [keyword.get_text() for keyword in soup.find("section",{"id":"authorKeywords"}).h3.find_next_siblings('span')]
    except:
        keywords=""
    return ';'.join(keywords)

def getIndexedKeywords(soup):    
    try:
        keywords = [keyword.get_text() for keyword in soup.find("section",{"id":"indexedKeywords"}).td]
    except:
        keywords=""
    return ';'.join(keywords)

def Abstract(eid):
    url = getContentURL(eid)
    soup = getContentSoup(url)
    abstract = getAbstract(soup)
    return abstract	

def Keywords(eid):
    url = getContentURL(eid)
    soup = getContentSoup(url)
    authorKeywords = getAuthorKeywords(soup)
    indexedKeywords = getIndexedKeywords(soup)
    Keywords = ','.join([authorKeywords ,indexedKeywords])
    return Keywords	

def processAbstracts():
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
                f.write(eid + '\n')

def processKeywords():
    keywordPath=r'D:\Projects\textMining\data\keywords'
    df = pd.read_csv(r'D:\Projects\textMining\data\scopus.csv')
    eid_list = list(df.EID)
    done = os.listdir(keywordPath)
    eid_list = list(set(eid_list) - set(done))
    for eid in eid_list:    
        try:
            keywords = Keywords(eid)
            with open(os.path.join(keywordPath,eid),'w') as f:
                f.write(keywords.encode('utf8'))
        except:
            with open(os.path.join(keywordPath,'errors'),'a') as f:
                f.write(eid + '\n')