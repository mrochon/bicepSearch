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

$dotEnv = Get-Content -Path ".env" | Where-Object { $_ -match '=' } | ForEach-Object {
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
$resource = "https://search.azure.com/"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $appSecret
    resource      = $resource
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $body
$token = $tokenResponse
$headers = @{
  'Authorization' = "Bearer $($token.Token)"
  'Content-Type' = 'application/json'
}
$bicepOutput = Get-Content -Path "./output-values.json" -Raw | ConvertFrom-Json
$body = Get-Content -Path "./json/dataSource.json" -Raw 
$body = $body -replace 'PROJECT_NAME', $bicepOutput.properties.outputs.projectName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.properties.outputs.subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.properties.outputs.rgName
$body = $body -replace 'STORAGEACCOUNT_NAME', $bicepOutput.properties.outputs.storageAcctName
$body = $body -replace 'CONTAINER_NAME', $bicepOutput.properties.outputs.containerName
$url="https://$($bicepOutput.properties.outputs.searchName).search.windows.net/datasources('$($bicepOutput.properties.outputs.projectName)-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $bicepOutput.properties.outputs.synonymMap
$body = $body -replace 'PROJECT_NAME', $bicepOutput.properties.outputs.projectName
$url="https://$($bicepOutput.properties.outputs.searchName).search.windows.net/synonymmaps('$($bicepOutput.properties.outputs.projectName)-map')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $bicepOutput.properties.outputs.index
$body = $body -replace 'PROJECT_NAME', $bicepOutput.properties.outputs.projectName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.properties.outputs.subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.properties.outputs.rgName
$body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.properties.outputs.openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.properties.outputs.searchIdentityName
$url="https://$($bicepOutput.properties.outputs.searchName).search.windows.net/indexes('$($bicepOutput.properties.outputs.projectName)-index')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $bicepOutput.properties.outputs.skillset
$body = $body -replace 'PROJECT_NAME', $bicepOutput.properties.outputs.projectName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.properties.outputs.subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.properties.outputs.rgName
$body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.properties.outputs.openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.properties.outputs.searchIdentityName
$url="https://$($bicepOutput.properties.outputs.searchName).search.windows.net/skillsets('$($bicepOutput.properties.outputs.projectName)-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $bicepOutput.properties.outputs.indexer
$body = $body -replace 'PROJECT_NAME', $bicepOutput.properties.outputs.projectName
$body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.properties.outputs.subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.properties.outputs.rgName
$body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.properties.outputs.openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.properties.outputs.searchIdentityName
$url="https://$($bicepOutput.properties.outputs.searchName).search.windows.net/indexers('$($bicepOutput.properties.outputs.projectName)-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body