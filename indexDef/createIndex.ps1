
# param(
#   [Parameter(Mandatory = $false)]
#   [string]$indexName
# )

$indexName = $args[0]
if (-not $indexName) {
  while (-not $indexName) {
    $indexName = Read-Host "Please enter the index name"
  }
}
function InvokeWithRetry($url, $headers, $body) {
  try {  
    Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
  } catch {
    $errorJson = @{
      error = $_.Exception.Message
      url = $url
    } | ConvertTo-Json
    # Set-Content -Path "error.json" -Value $errorJson
    Write-Host "Error occurred: $($errorJson)"
    throw $_
  }
}  

function UpdateBody($body, $indexName, $bicepOutput) {
  $body = $body -replace 'INDEX_NAME', $indexName
  $body = $body -replace 'SUBSCRIPTION_ID', $bicepOutput.subscriptionId.value
  $body = $body -replace 'RESOURCEGROUP_NAME', $bicepOutput.rgName.value
  $body = $body -replace 'STORAGEACCOUNT_NAME', $bicepOutput.storageAcctName.value
  $body = $body -replace 'CONTAINER_NAME', $indexName # $bicepOutput.containerName.value
  $body = $body -replace 'OPENAI_ENDPOINT', $bicepOutput.openaiEndpoint.value
  $body = $body -replace 'SEARCH_IDENTITY_NAME', $bicepOutput.searchIdentityName.value  
  $body = $body -replace 'EMBEDDING_DEPLOYMENT_NAME', $bicepOutput.embeddingDeployment.value
  return $body
}

if (-not (Test-Path -Path "./indexDefinitions/$indexName")) {
  Write-Error "The path './indexDefinitions/$indexName' does not exist."
  exit 1
}

$dotEnv = Get-Content -Path "./.env" | Where-Object { $_ -match '=' } | ForEach-Object {
    $parts = $_ -split '=', 2
    [PSCustomObject]@{ Key = $parts[0].Trim(); Value = $parts[1].Trim() }
} | Group-Object -Property Key -AsHashTable -AsString | ForEach-Object {
    $obj = [PSCustomObject]@{}
    foreach ($key in $_.Keys) {
        Add-Member -InputObject $obj -MemberType NoteProperty -Name $key -Value $_[$key].Value
    }
    $obj | Add-Member -MemberType NoteProperty -Name 'IndexName' -Value $indexName -Force
    $obj
}


$dotEnv = $dotEnv[0]
$appId = $dotEnv.AZURE_CLIENT_ID
$appSecret = $dotEnv.AZURE_CLIENT_SECRET
$tenantId = $dotEnv.AZURE_TENANT_ID

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

Write-Host "Creating datasource"
$body = Get-Content -Path "./indexDefinitions/$IndexName/dataSource.json" -Raw 
$body = UpdateBody $body $indexName $bicepOutput
$url="https://$($bicepOutput.searchName.value).search.windows.net/datasources('$($indexName)-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

Write-Host "Creating index"
$body = Get-Content -Path "./indexDefinitions/$IndexName/index.json" -Raw 
$body = UpdateBody $body $indexName $bicepOutput
$url="https://$($bicepOutput.searchName.value).search.windows.net/indexes('$($indexName)-index')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

Write-Host "Creating skillset"
$body = Get-Content -Path "./indexDefinitions/$IndexName/skillset.json" -Raw 
$body = UpdateBody $body $indexName $bicepOutput
$url="https://$($bicepOutput.searchName.value).search.windows.net/skillsets('$($indexName)-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

Write-Host "Creating indexer"
$body = Get-Content -Path "./indexDefinitions/$IndexName/indexer.json" -Raw 
$body = $body -replace 'INDEX_NAME', $indexName
$url="https://$($bicepOutput.searchName.value).search.windows.net/indexers('$($indexName)-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

Write-Host "Done"