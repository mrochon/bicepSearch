import sys
import os
import json
import requests
from azure.identity import DefaultAzureCredential

if len(sys.argv) > 1:
    indexName = sys.argv[1]
else:
    indexName = ""

while not indexName:
    indexName = input("Please enter the index name: ")

def invoke_with_retry(url, headers, body, method="PUT", max_retries=1):
    for attempt in range(max_retries):
        response = requests.request(method, url, headers=headers, data=body)
        if response.ok:
            return response
        else:
            print(response.text)
    exit(1)

def update_body(body, indexName, bicepOutput):
    body = body.replace('INDEX_NAME', indexName)
    body = body.replace('SUBSCRIPTION_ID', bicepOutput['subscriptionId']['value'])
    body = body.replace('RESOURCEGROUP_NAME', bicepOutput['rgName']['value'])
    body = body.replace('STORAGEACCOUNT_NAME', bicepOutput['storageAcctName']['value'])
    body = body.replace('CONTAINER_NAME', indexName) # or bicepOutput['containerName']['value']
    body = body.replace('OPENAI_ENDPOINT', bicepOutput['openaiEndpoint']['value'])
    body = body.replace('SEARCH_IDENTITY_NAME', bicepOutput['searchIdentityName']['value'])
    body = body.replace('EMBEDDING_DEPLOYMENT_NAME', bicepOutput['embeddingDeployment']['value'])
    return body

app_dir = os.path.dirname(os.path.abspath(__file__))
index_definitions_path = os.path.join(app_dir, "indexDefinitions", indexName)
if not os.path.exists(index_definitions_path):
    print(f"The path '{index_definitions_path}' does not exist.")
    exit(1)

with open(os.path.join(app_dir, "bicepOutput.json"), "r") as f:
    bicepOutput = json.load(f)
    
credential = DefaultAzureCredential()
token = credential.get_token("https://search.azure.com/.default").token
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

objectPath = os.path.join(app_dir, "indexDefinitions", indexName)
search_url = f"https://{bicepOutput['searchName']['value']}.search.windows.net"
print("Creating datasource")
with open(f"{objectPath}/dataSource.json", "r") as f:
    body = f.read()
body = update_body(body, indexName, bicepOutput)
url = f"{search_url}/datasources('{indexName}-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
invoke_with_retry(url, headers, body)

print("Creating index")
with open(f"{objectPath}/index.json", "r") as f:
    body = f.read()
body = update_body(body, indexName, bicepOutput)
url = f"{search_url}/indexes('{indexName}-index')?allowIndexDowntime=True&api-version=2024-07-01"
invoke_with_retry(url, headers, body)

print("Creating skillset")
with open(f"{objectPath}/skillset.json", "r") as f:
    body = f.read()
body = update_body(body, indexName, bicepOutput)
url = f"{search_url}/skillsets('{indexName}-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
invoke_with_retry(url, headers, body)

print("Creating indexer")
with open(f"{objectPath}/indexer.json", "r") as f:
    body = f.read()
body = body.replace('INDEX_NAME', indexName)
url = f"{search_url}/indexers('{indexName}-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
invoke_with_retry(url, headers, body)

print("Done")