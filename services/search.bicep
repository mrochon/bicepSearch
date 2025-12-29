metadata description = 'Creates an Azure AI Search instance.'
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
param aiProjectPrincipalId string
param workspaceId string

param serviceName string 

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: serviceName
  location: location
  tags: tags
  identity: {
    // SystemAssigned has to be created, otherwise indexer throws: Ensure managed identity is enabled for your service
    type: 'SystemAssigned'
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

// Allow AI Project to access search service
var dataReader = '1407120a-92aa-4202-b7e9-c0e197c71c8f' // Search Index Data Reader
resource aiReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceName, dataReader)
  scope: search
  properties: {
    //delegatedManagedIdentityResourceId: searchManagedIdentityId
    description: 'Search Index Data Reader'
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', dataReader)
  }
}
var svcContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0' // Search Service Contributor
resource aiContrAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceName, svcContributor)
  scope: search
  properties: {
    //delegatedManagedIdentityResourceId: searchManagedIdentityId
    description: 'Search Service Contributor'
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', svcContributor)
  }
}

// Diagnostic settings to send metrics and logs to Log Analytics
resource searchDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'search-diagnostics'
  scope: search
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}



// Since scripModule is removed
// resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
//   name: 'script-${uniqueName}-identity'
//   location: location
//   tags: tags
// }

// resource scriptRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid('script', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
//   scope: search
//   properties: {
//     //delegatedManagedIdentityResourceId: searchManagedIdentityId
//     description: 'Search service contributor'
//     principalId: scriptIdentity.properties.principalId
//     principalType: 'ServicePrincipal'
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
//   }
// }

output id string = search.id
output endpoint string = 'https://${serviceName}.search.windows.net/'
output name string = serviceName
output searchSysAssignedPrincipalId string = search.identity.principalId
//output searchScriptIdentityId string = scriptIdentity.id
// output searchUAIdentityName string = search.identity.userAssignedIdentities[searchUAIdentityPrincipalId].name
