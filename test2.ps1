$datasource = Get-Content -Path "json/datasource.json" -Raw
$env:rgName = "rg-bicepsearch3"
$env:searchName = "search_name"
$env:dataSourceName = "dataSourceName"
$env:storageAcctName = "storageAcctName"
$env:containerName = "containerName"
$env:indexName = "index-bicepsearch3"
$env:subscriptionId = "12345678-1234-5678-123456789012"

$datasource = $datasource -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$datasource = $datasource -replace 'RESOURCEGROUP_NAME', $env:rgName
$datasource = $datasource -replace 'STORAGEACCOUNT_NAME', $env:storageAcctName
$datasource = $datasource -replace 'CONTAINER_NAME', $env:containerName

$jsonBody = $datasource
$url = "https://mrfunctions.azurewebsites.net/api/ReceiveCall?"
# $url="https://$($env:searchName).search.windows.net/datasources('$($env:dataSourceName)')?allowIndexDowntime=True&api-version=2024-07-01"
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $jsonBody
"Finished"