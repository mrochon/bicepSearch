targetScope = 'resourceGroup'

metadata description = 'Creates an Azure AI Search instance.'
param projectName string
param uniqueName string
param location string = resourceGroup().location
param tags object = {}
param openaiEndpoint string
param searchIdentityName string

param sku string = 'standard'


param disabledDataExfiltrationOptions array = []
param encryptionWithCmk object = {
  enforcement: 'Unspecified'
}
@allowed([
  'default'
  'highDensity'
])
param hostingMode string = 'default'
param networkRuleSet object = {
  bypass: 'None'
  ipRules: []
}
param partitionCount int = 1
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'
param replicaCount int = 1
@allowed([
  'disabled'
  'free'
  'standard'
])
param semanticSearch string = 'free'

param storageAcctName string
param containerName string

var search_name = 'search-${uniqueName}'

resource searchIdentityProvider 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${search_name}-identity'
  location: location
  tags: tags
}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: search_name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${searchIdentityProvider.id}': {}
    }
  }
  properties: {
    disableLocalAuth: true
    authOptions: null
    disabledDataExfiltrationOptions: disabledDataExfiltrationOptions
    encryptionWithCmk: encryptionWithCmk
    hostingMode: hostingMode
    networkRuleSet: networkRuleSet
    partitionCount: partitionCount
    publicNetworkAccess: publicNetworkAccess
    replicaCount: replicaCount
    semanticSearch: semanticSearch
  }
  sku: { name: sku }
}

resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'script-${uniqueName}-identity'
  location: location
  tags: tags
}

resource scriptRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('script', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
  scope: search
  properties: {
    //delegatedManagedIdentityResourceId: searchManagedIdentityId
    description: 'Search service contributor'
    principalId: scriptIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'searchSetup'
  dependsOn: [scriptRoleAssignment]
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
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
        value: search_name
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
        value: '${search_name}-identity'
      } 
    ]    
    scriptContent: '''
$debug = $true
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
if ($debug) {
  $url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
} else {
    $url="https://$($env:searchName).search.windows.net/datasources('$($env:projectName)-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
}
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body

$body = $env:synonymMap
$body = $body -replace 'PROJECT_NAME', $env:projectName
if ($debug) {
  $url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
} else {
    $url="https://$($env:searchName).search.windows.net/synonymmaps('$($env:projectName)-map')?allowIndexDowntime=True&api-version=2024-07-01"
}
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body

$body = $env:index
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
if ($debug) {
  $url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
} else {
    $url="https://$($env:searchName).search.windows.net/indexes('$($env:PROJECT_NAME)-index')?allowIndexDowntime=True&api-version=2024-07-01"
}
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body

$body = $env:skillset
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
if ($debug) {
  $url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
} else {
    $url="https://$($env:searchName).search.windows.net/skillsets('$($env:projectName)-skillset')?allowIndexDowntime=True&api-version=2024-07-01"
}
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body

$body = $env:indexer
$body = $body -replace 'PROJECT_NAME', $env:projectName
$body = $body -replace 'SUBSCRIPTION_ID', $env:subscriptionId
$body = $body -replace 'RESOURCEGROUP_NAME', $env:rgName
$body = $body -replace 'OPENAI_ENDPOINT', $env:openaiEndpoint
$body = $body -replace 'SEARCH_IDENTITY_NAME', $env:searchIdentityName
if ($debug) {
  $url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?searchName=$($env:searchName)"
} else {
    $url="https://$($env:searchName).search.windows.net/indexers('$($env:projectName)-indexer')?allowIndexDowntime=True&api-version=2024-07-01"
}
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

output id string = search.id
output endpoint string = 'https://${search_name}.search.windows.net/'
output name string = search_name
output identityId string = searchIdentityProvider.id
output identityPrincipalId string = searchIdentityProvider.properties.principalId
