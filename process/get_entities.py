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
        content=text,
        type=enums.Document.Type.PLAIN_TEXT)

    # Detects entities in the document. You can also analyze HTML with:
    #   document.type == enums.Document.Type.HTML
    entities = client.analyze_entities(document).entities

    response = parse_response(entities)
    
    return response

for index, row in data[1:10].iterrows():
    
    abstract = row['text']
    keywords = row['keywords']
    title = row['Title']
    
    abs_entities = get_entities(abstract)
    f = open(OUT_DIR + row['EID'] + '-abstract', 'wb')
    f.write(json.dumps(abs_entities, ensure_ascii=False).encode('utf-8'))
    f.close()

    if keywords != ',':
        kw_entities = get_entities(keywords)
        f = open(OUT_DIR + row['EID'] + '-keywords', 'wb')
        f.write(json.dumps(kw_entities, ensure_ascii=False).encode('utf-8'))
        f.close()

    title_entities = get_entities(title)
    f = open(OUT_DIR + row['EID'] + '-title', 'wb')
    f.write(json.dumps(title_entities, ensure_ascii=False).encode('utf-8'))
    f.close()
    
    print(index)
