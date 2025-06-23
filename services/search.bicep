

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
param searchUAIdentityId string
param aiUAIdentityPrincipalId string

var search_name = 'search-${uniqueName}'

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: search_name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${searchUAIdentityId}': {}
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

// Allow AI to access search service
resource aiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('ai', '1407120a-92aa-4202-b7e9-c0e197c71c8f')
  scope: search
  properties: {
    //delegatedManagedIdentityResourceId: searchManagedIdentityId
    description: 'Search Index Data Reader'
    principalId: aiUAIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '1407120a-92aa-4202-b7e9-c0e197c71c8f')
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
output endpoint string = 'https://${search_name}.search.windows.net/'
output name string = search_name
output searchSAIdentityPrincipalId string = search.identity.principalId
//output searchScriptIdentityId string = scriptIdentity.id
// output searchUAIdentityName string = search.identity.userAssignedIdentities[searchUAIdentityPrincipalId].name
