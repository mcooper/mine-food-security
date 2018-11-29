# Imports the Google Cloud client library
from google.cloud import language
from google.cloud.language import enums
from google.cloud.language import types
from google.protobuf.json_format import MessageToJson
import json
import six

import os

os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="C://Git/mine-food-security/api_keys.json"

FILES_DIR = "C://Git/mine-food-security/data/abstracts/"
OUT_DIR = "C://Git/mine-food-security/data/entities/"

os.chdir(FILES_DIR)

client = language.LanguageServiceClient()

def parse_response(entities):
    response = [json.loads(MessageToJson(x)) for x in entities]
    return response

for eid in os.listdir(".")[22096: ]:
    abstract = open(eid, 'rb+').read()
    abstract = abstract[ : abstract.find('©')]
    
    if abstract in ['[No abstract available',  '', 'Abstract available from the publisher']:
        pass
    
    #Documentation: https://cloud.google.com/natural-language/docs/analyzing-entities#language-entities-string-python
    if isinstance(abstract, six.binary_type):
        abstract = abstract.decode('utf-8')

    # Instantiates a plain text document.
    document = types.Document(
        content=abstract,
        type=enums.Document.Type.PLAIN_TEXT)

    # Detects entities in the document. You can also analyze HTML with:
    #   document.type == enums.Document.Type.HTML
    entities = client.analyze_entities(document).entities

    response = parse_response(entities)
    
    f = open(OUT_DIR + eid, 'wb')
    f.write(json.dumps(response, ensure_ascii=False).encode('utf-8'))
    f.close()
    
    print(os.listdir(".").index(eid))