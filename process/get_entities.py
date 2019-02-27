# Imports the Google Cloud client library
from google.cloud import language
from google.cloud.language import enums
from google.cloud.language import types
from google.protobuf.json_format import MessageToJson
import json
import six
import pandas as pd
import os
import re

os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="C://Git/mine-food-security/api_keys.json"

FILES_DIR = "C://Git/mine-food-security/data/"
OUT_DIR = "C://Git/mine-food-security/data/entities/"

os.chdir(FILES_DIR)

client = language.LanguageServiceClient()

data = pd.read_csv('abstracts.csv')

data = data.fillna('')

def re_clean(string):
    #get rid of.. this
    #string = re.sub(r'\.\.|\.,|,;|\. ,|\. ;|. .', '.', string)
    #get rid of.this
    string = re.sub(r'(?<=[.,;!?])(?=[^\s])', ' ', string)
    return string
    
def parse_response(entities):
    response = [json.loads(MessageToJson(x)) for x in entities]
    return response

def get_entities(text):
    #Documentation: https://cloud.google.com/natural-language/docs/analyzing-entities#language-entities-string-python
    if isinstance(text, six.binary_type):
        text = text.decode('utf-8')

    # Instantiates a plain text document.
    document = types.Document(
        content=re_clean(text),
        type=enums.Document.Type.PLAIN_TEXT)

    # Detects entities in the document. You can also analyze HTML with:
    #   document.type == enums.Document.Type.HTML
    try:
        entities = client.analyze_entities(document).entities
        response = parse_response(entities)
    except Exception as e:
        response = repr(e)
        print(e)
    
    return response

def process_text(text, part, eid, alreadydone):
    filename = eid + '-' + part
    
    #Check first if already been done, in case I need to re-run the for loop
    if filename in alreadydone:
        pass
    else:
        entities = get_entities(text)
        f = open(OUT_DIR + filename, 'wb')
        f.write(json.dumps(entities, ensure_ascii=False).encode('utf-8'))
        f.close()

alreadydone = os.listdir(OUT_DIR)
for index, row in data.iterrows():
    
    eid = row['EID']
    
    abstract = row['text']
    keywords = row['keywords']
    title = row['Title']
    
    process_text(abstract, 'abstract', eid, alreadydone)
    if keywords != ',':
        process_text(keywords, 'keywords', eid, alreadydone)
    process_text(title, 'title', eid, alreadydone)
    
    print(index)
