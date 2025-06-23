function InvokeWithRetry($url, $headers, $body) {
  try {  
    Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
  } catch {
    $errorJson = @{
      error = $_.Exception.Message
      url = $url
    } | ConvertTo-Json
    Set-Content -Path "error.json" -Value $errorJson
    throw $_
  }
}  

$dotEnv = Get-Content -Path "./.env" | Where-Object { $_ -match '=' } | ForEach-Object {
    $parts = $_ -split '=', 2
    [PSCustomObject]@{ Key = $parts[0].Trim(); Value = $parts[1].Trim() }
} | Group-Object -Property Key -AsHashTable -AsString | ForEach-Object {
    $obj = [PSCustomObject]@{}
    foreach ($key in $_.Keys) {
        Add-Member -InputObject $obj -MemberType NoteProperty -Name $key -Value $_[$key].Value
    }
    $obj
}
$dotEnv = $dotEnv[0]
$appId = $dotEnv.AZURE_CLIENT_ID
$appSecret = $dotEnv.AZURE_CLIENT_SECRET
$tenantId = $dotEnv.AZURE_TENANT_ID
$indexName = $dotEnv.INDEX_NAME
$scope = "https://search.azure.com/.default"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $appSecret
    scope      = $scope
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $body
$token = $tokenResponse.access_token
$headers = @{
  'Authorization' = "Bearer $($token)"
  'Content-Type' = 'application/json'
}
$bicepOutput = Get-Content -Path "./bicepOutput.json" -Raw | ConvertFrom-Json
$body = Get-Content -Path "./searchDefinition/dataSource.json" -Raw 
$body = $body -replace 'INDEX_NAME', $indexName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.subscriptionId.value
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.rgName.value
$body = $body -replace 'STORAGEACCOUNT_NAME', $bicepOutput.storageAcctName.value
$body = $body -replace 'CONTAINER_NAME', $bicepOutput.containerName.value
$url="https://$($bicepOutput.searchName.value).search.windows.net/datasources('$($indexName)-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = Get-Content -Path "./searchDefinition/index.json" -Raw 
$body = $body -replace 'INDEX_NAME', $indexName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.subscriptionId.value
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.rgName.value
$body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.openaiEndpoint.value
$body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.searchIdentityName.value
$url="https://$($bicepOutput.searchName.value).search.windows.net/indexes('$($indexName)-index')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = Get-Content -Path "./searchDefinition/skillset.json" -Raw 
$body = $body -replace 'INDEX_NAME', $indexName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.subscriptionId.value
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.rgName.value
$body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.openaiEndpoint.value
$body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.searchIdentityName.value
$url="https://$($bicepOutput.searchName.value).search.windows.net/skillsets('$($indexName)-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = Get-Content -Path "./searchDefinition/indexer.json" -Raw 
$body = $body -replace 'INDEX_NAME', $indexName
$url="https://$($bicepOutput.searchName.value).search.windows.net/indexers('$($indexName)-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body