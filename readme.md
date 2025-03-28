## Deployment

```
az deployment sub create --name bicespsearch2 \
  --template-file main.bicep \
  --parameters @main.parameters.json \
  --location 'eastus' \
  --subscription '7cee9002-39e6-44f8-a673-6f8680f8f4ad'

```

```
az deployment sub delete --name rg-searchbicep2
```

```
./test.ps1 'rg-bicepsearch2' 'search-t43soeccwpx5s' datasource storaget43soeccwpx5s searchdata '7cee9002-39e6-44f8-a673-6f8680f8f4ad'
```

```
$url="https://$($env:searchName).search.windows.net/datasources('$($env:dataSourceName)')?allowIndexDowntime=True&api-version=2024-07-01"
```

## Trace of script call

```
2025-03-28T02:59:19Z   [Information]   Header: Host = mrfunctions.azurewebsites.net
2025-03-28T02:59:19Z   [Information]   Header: User-Agent = Mozilla/5.0 (Linux; Linux 5.10.102.2-microsoft-standard #1 SMP Mon Mar 7 17:36:34 UTC 2022; en-US) PowerShell/7.2.24
2025-03-28T02:59:19Z   [Information]   Header: Authorization = Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6IkpETmFfNGk0cjdGZ2lnTDNzSElsSTN4Vi1JVSIsImtpZCI6IkpETmFfNGk0cjdGZ2lnTDNzSElsSTN4Vi1JVSJ9.eyJhdWQiOiJodHRwczovL3NlYXJjaC5henVyZS5jb20vIiwiaXNzIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMTE2NTQ5MGMtODliNS00NjNiLWIyMDMtOGI3N2UwMTU5N2QyLyIsImlhdCI6MTc0MzEwODk0MywibmJmIjoxNzQzMTA4OTQzLCJleHAiOjE3NDMxOTU2NDMsImFpbyI6ImsyUmdZTEJtMmRBcEhtTFg4S2psN1FXK3kxM25BQT09IiwiYXBwaWQiOiJmNmMwMmIyNC1mNjQyLTQwN2QtOTA5Ni00MzU2NDQzNjZmY2EiLCJhcHBpZGFjciI6IjIiLCJpZHAiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC8xMTY1NDkwYy04OWI1LTQ2M2ItYjIwMy04Yjc3ZTAxNTk3ZDIvIiwiaWR0eXAiOiJhcHAiLCJvaWQiOiIwOTIxYjJkOS1hNzA0LTQwYWEtOTY4Mi0wMTQ5NDA0Yjk5OTMiLCJyaCI6IjEuQUwwQURFbGxFYldKTzBheUE0dDM0QldYMG9DakRZaGVtSmhCZ2JuZ1d4ekZNVmdEQVFDOUFBLiIsInN1YiI6IjA5MjFiMmQ5LWE3MDQtNDBhYS05NjgyLTAxNDk0MDRiOTk5MyIsInRpZCI6IjExNjU0OTBjLTg5YjUtNDYzYi1iMjAzLThiNzdlMDE1OTdkMiIsInV0aSI6IldUd21jdnNtbVV5N0w4U1ZUbnhwQVEiLCJ2ZXIiOiIxLjAiLCJ4bXNfaWRyZWwiOiI3IDE0IiwieG1zX21pcmlkIjoiL3N1YnNjcmlwdGlvbnMvN2NlZTkwMDItMzllNi00NGY4LWE2NzMtNmY4NjgwZjhmNGFkL3Jlc291cmNlZ3JvdXBzL3JnLWJpY2Vwc2VhcmNoMi9wcm92aWRlcnMvTWljcm9zb2Z0Lk1hbmFnZWRJZGVudGl0eS91c2VyQXNzaWduZWRJZGVudGl0aWVzL3NjcmlwdC10NDNzb2VjY3dweDVzLWlkZW50aXR5In0.MGO78cxG6xKqLkgCndUBC8MCDLBW6EzPxMNth-zWVHRny-7mSIydU2jdobtgdk9fRB_JLaz4uw3wQ1yC0mzjQACE6KiduuG5K9p-Avyu14lETXAK2-bNvXEvnlHMu7Su5PHnS7GVaNhlV1TiFOhiuNfPFEAGEv0HP_jRd2jUW0qv08zyYG7W7pfi75IsmfqCqFRTfdooZbEYChpYGosEIyxKK-2J3G2ttCJgPHKms1h393WvddaMiAwgvAbosE2HDkseZjBjKJeyt1hmkVZlZjZQhZTpwUsaD-nQHHq9VFAufAZuCJxQSJFEOuz-p1sgrtjz5hd7bEj5ZHFA6rx_pw
2025-03-28T02:59:19Z   [Information]   Header: Content-Type = application/json
2025-03-28T02:59:19Z   [Information]   Header: Max-Forwards = 10
2025-03-28T02:59:19Z   [Information]   Header: traceparent = 00-8b8ee85c93c3b841f48e27a17e53a303-73c916a3feb14446-00
2025-03-28T02:59:19Z   [Information]   Header: Content-Length = 492
2025-03-28T02:59:19Z   [Information]   Header: X-ARR-LOG-ID = 77dc1e96-45be-4e35-b05b-6ef970a8f70e
2025-03-28T02:59:19Z   [Information]   Header: CLIENT-IP = 172.212.68.176:10752
2025-03-28T02:59:19Z   [Information]   Header: DISGUISED-HOST = mrfunctions.azurewebsites.net
2025-03-28T02:59:19Z   [Information]   Header: X-SITE-DEPLOYMENT-ID = mrfunctions
2025-03-28T02:59:19Z   [Information]   Header: WAS-DEFAULT-HOSTNAME = mrfunctions.azurewebsites.net
2025-03-28T02:59:19Z   [Information]   Header: X-AppService-Proto = https
2025-03-28T02:59:19Z   [Information]   Header: X-ARR-SSL = 2048|256|CN=Microsoft Azure RSA TLS Issuing CA 04, O=Microsoft Corporation, C=US|CN=*.azurewebsites.net, O=Microsoft Corporation, L=Redmond, S=WA, C=US
2025-03-28T02:59:19Z   [Information]   Header: X-Forwarded-TlsVersion = 1.3
2025-03-28T02:59:19Z   [Information]   Header: X-Original-URL = /api/ReceiveCall?searchName=search-t43soeccwpx5s&dataSourceName=sourceData&storageAcctName=storaget43soeccwpx5s&containerName=searchdata
2025-03-28T02:59:19Z   [Information]   Header: X-WAWS-Unencoded-URL = /api/ReceiveCall?searchName=search-t43soeccwpx5s&dataSourceName=sourceData&storageAcctName=storaget43soeccwpx5s&containerName=searchdata
2025-03-28T02:59:19Z   [Information]   Header: x-ms-invocation-id = 5e2ebcbb-8d90-4d54-8745-e5e10d61b906
2025-03-28T02:59:19Z   [Information]   Header: X-Original-Proto = http
2025-03-28T02:59:19Z   [Information]   Header: X-Original-Host = localhost:41943
2025-03-28T02:59:19Z   [Information]   Header: X-Original-For = [::1]:51900
2025-03-28T02:59:19Z   [Information]   Query Parameter: searchName = search-t43soeccwpx5s
2025-03-28T02:59:19Z   [Information]   Query Parameter: dataSourceName = sourceData
2025-03-28T02:59:19Z   [Information]   Query Parameter: storageAcctName = storaget43soeccwpx5s
2025-03-28T02:59:19Z   [Information]   Query Parameter: containerName = searchdata
2025-03-28T02:59:19Z   [Information]   Request Body: {
  "type": "azureblob",
  "container": {
    "query": "",
    "name": "searchdata"
  },
  "credentials": {
    "connectionString": "ResourceId=/subscriptions/7cee9002-39e6-44f8-a673-6f8680f8f4ad/resourceGroups/rg-bicepsearch2/providers/Microsoft.Storage/storageAccounts/storaget43soeccwpx5s;"
  },
  "description": "Tech documents.",
  "name": "sourceData",
  "url": "https://search-t43soeccwpx5s.search.windows.net/datasources('sourceData')?allowIndexDowntime=True&api-version=2024-07-01"
}
```