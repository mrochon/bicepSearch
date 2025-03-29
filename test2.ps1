$uniqueName='gxq7lyngidvio'
$body = Get-Content -Path "json/index.json" -Raw
$env:rgName = "rg-bicepsearch3"
$env:searchName = "search_name"
$env:bodyName = "bodyName"
$env:storageAcctName = "storageAcctName"
$env:containerName = "containerName"
$env:indexName = "index-bicepsearch3"
$env:subscriptionId = "7cee9002-39e6-44f8-a673-6f8680f8f4ad"
$env:openaiEndpoint = "https://ai-${uniqueName}openai.com"
$env:searchIdentityName = "search-${uniqueName}"
foreach ($val in Get-ChildItem Env:) {
    Write-Host "$($val.Key) = $($val.Value)"
}

$body = $body -replace 'INDEX_NAME', $env:indexName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
$debug = $false
if ($debug) {
    $url = "https://mrfunctions.azurewebsites.net/api/ReceiveCall?"
} else {
    $url="https://$($env:searchName).search.windows.net/bodys('$($env:bodyName)')?allowIndexDowntime=True&api-version=2024-07-01"
}
$url
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
"Finished"