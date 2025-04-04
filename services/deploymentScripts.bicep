targetScope = 'resourceGroup'

param location string = resourceGroup().location
param projectName string
param openaiEndpoint string
@secure()
param searchScriptIdentityId string
param searchName string
param storageAcctName string
param containerName string
param searchUAIdentityName string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'searchSetup'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${searchScriptIdentityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '7.5.0'
    environmentVariables: [
      {
        name: 'projectName'
        value: projectName
      }  
      {
        name: 'subscriptionId'
        value: subscription().subscriptionId
      }      
      {
        name: 'dataSource'
        value: loadTextContent('../json/datasource.json', 'utf-8')
      }
      {
        name: 'synonymMap'
        value: loadTextContent('../json/synonymmap.json', 'utf-8')
      }      
      {
        name: 'index'
        value: loadTextContent('../json/index.json', 'utf-8')
      }  
      {
        name: 'skillset'
        value: loadTextContent('../json/skillset.json', 'utf-8')
      }    
      {
        name: 'indexer'
        value: loadTextContent('../json/indexer.json', 'utf-8')
      }                    
      {
        name: 'rgName'
        value: resourceGroup().name
      }
      {
        name: 'searchName'
        value: searchName
      }
      {
        name: 'storageAcctName'
        value: storageAcctName
      }
      {
        name: 'containerName'
        value: containerName
      }
      {
        name: 'openaiEndpoint'
        value: openaiEndpoint
      }
      {
        name: 'searchIdentityName'
        value: searchUAIdentityName
      } 
    ]    
    scriptContent: '''
function InvokeWithRetry($url, $headers, $body) {
  try {  
    Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
  } catch {
    $errorJson = @{
      error = $_.Exception.Message
      url = $url
    } | ConvertTo-Json
    $retryUrl = "https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
    Invoke-RestMethod -Uri $retryUrl -Method PUT -Body $errorJson  
    Invoke-RestMethod -Uri $retryUrl -Method PUT -Headers $headers -Body $body
    throw $_
  }
}    
$debug = $false
$token = Get-AzAccessToken -ResourceUrl "https://search.azure.com/"
$headers = @{
  'Authorization' = "Bearer $($token.Token)"
  'Content-Type' = 'application/json'
}

$body = $env:dataSource
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'STORAGEACCOUNT_NAME', $env:storageAcctName
$body = $body -replace 'CONTAINER_NAME', $env:containerName
$url="https://$($env:searchName).search.windows.net/datasources('$($env:projectName)-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $env:synonymMap
$body = $body -replace 'PROJECT_NAME', $env:projectName
$url="https://$($env:searchName).search.windows.net/synonymmaps('$($env:projectName)-map')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $env:index
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
$url="https://$($env:searchName).search.windows.net/indexes('$($env:projectName)-index')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $env:skillset
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
$url="https://$($env:searchName).search.windows.net/skillsets('$($env:projectName)-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body

$body = $env:indexer
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
$url="https://$($env:searchName).search.windows.net/indexers('$($env:projectName)-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
InvokeWithRetry $url $headers $body
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
