
param(
  [Parameter(Mandatory = $false)]
  [string]$indexName,
  
  [Parameter(Mandatory = $false)]
  [switch]$generateOnly = $false
)

$indexName = $args[0]

if (-not $indexName) {
  while (-not $indexName) {
    $indexName = Read-Host "Please enter the index name"
  }
  if (-not (Test-Path -Path "./indexDefinitions/$indexName")) {
    Write-Error "The path './indexDefinitions/$indexName' does not exist."
    $indexName = $null
  }
}

function InvokeWithRetry($url, $headers, $body) {
  try {  
    if($generateOnly) {
      $output = @{
        url = $url
        headers = $headers
        body = $body
      } | ConvertTo-Json
      if (-not (Test-Path -Path "./tmp")) {
        New-Item -Path "./tmp" -ItemType Directory | Out-Null
      }
      $fileName = "./tmp/$($indexName)_$(Get-Random).json"
      Set-Content -Path $fileName -Value $output
      Write-Host "Generated file: $fileName"
      return
    } 
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

# Get access token using DefaultAzureCredential
$credential = New-Object Azure.Identity.DefaultAzureCredential
$tokenRequestContext = New-Object Azure.Core.TokenRequestContext
$tokenRequestContext.Scopes = @("https://search.azure.com/.default")
$accessToken = $credential.GetToken($tokenRequestContext, [System.Threading.CancellationToken]::None)
$token = $accessToken.Token
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