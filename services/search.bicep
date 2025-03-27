targetScope = 'resourceGroup'

metadata description = 'Creates an Azure AI Search instance.'
param uniqueName string
param location string = resourceGroup().location
param tags object = {}

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

param dataSourceName string
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
    scriptContent: '''
$token = Get-AzAccessToken -ResourceUrl "https://search.azure.com/"
$headers = @{
  'Authorization' = "Bearer $($token.Token)"
  'Content-Type' = 'application/json'
}
$body = @{
  name = $env:dataSourceName
  description = "Tech documents."
  type = "azureblob"
  credentials = @{
    connectionString = "ResourceId=/subscriptions/$($env:subscriptionId)/resourceGroups/$($env:rgName)/providers/Microsoft.Storage/storageAccounts/$($env:storageAcctName);"
  }
  container = @{
    name = $env:containerName
    query = ""
  }
}
$jsonBody = $body | ConvertTo-Json -Depth 10
$url="https://$($env:searchName).search.windows.net/datasources('$($env:dataSourceName)')?allowIndexDowntime=True&api-version=2024-07-01"
$resp = Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $jsonBody
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    environmentVariables: [
      {
        name: 'rgName'
        value: resourceGroup().name
      }
      {
        name: 'searchName'
        value: search_name
      }
      {
        name: 'dataSourceName'
        value: dataSourceName
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
        name: 'subscriptionId'
        value: subscription().subscriptionId
      }
    ]
    retentionInterval: 'P1D'
  }
}

output id string = search.id
output endpoint string = 'https://${search_name}.search.windows.net/'
output name string = search_name
output identityId string = searchIdentityProvider.id
output identityPrincipalId string = searchIdentityProvider.properties.principalId
