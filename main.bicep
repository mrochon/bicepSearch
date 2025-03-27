targetScope = 'subscription'

@minLength(6)
@maxLength(64)
@description('Name of the project. Part of resource group name. Also used to generate unique names for all resources.')
param projectName string

@minLength(1)
@description('Llocation for all resources')
param location string

@description('Tags to be applied top all resources')
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': projectName
}

// Search params
@description('SKU name of the Search Service')
@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param searchSkuName string = 'standard'

@description('Number of replica copies for the service')
@minValue(1)
@maxValue(12)
param searchReplicaCount int = 1

@description('Number of partitions for the service')
@allowed([
  1
  2
  3
  4
  6
  12
])
param searchPartitionCount int = 1

@description('Whether public network access is allowed')
@allowed([
  'enabled'
  'disabled'
])
param searchPublicNetworkAccess string = 'enabled'

param containers array = [
  'searchdata'
]

var uniqueName = toLower(uniqueString(subscription().id, projectName, location))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${projectName}'
  location: location
  tags: tags
}

module storage 'services/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    tags: tags
    location: location
    name: uniqueName
    containers: containers
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: true
    allowSharedKeyAccess: false
    corsRules: []
    defaultToOAuthAuthentication: false
    deleteRetentionPolicy: {}
    dnsEndpointType: 'Standard'
    isHnsEnabled: false
    kind: 'StorageV2'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    searchManagedIdentityPrincipalId: searchService.outputs.identityPrincipalId
  }
}

@description('Creates an Azure OpenAI services.')
module ai 'services/ai.bicep' = {
  scope: rg
  name: 'ai'
  params: {
    tags: tags
    location: location
    name: 'ai-${uniqueName}'
    searchManagedIdentityPrincipalId: searchService.outputs.identityPrincipalId
  }
}

@description('Creates an Azure AI Search service.')
module searchService 'services/search.bicep' = {
  scope: rg
  name:  'search'
  params: {
    tags: tags
    location: location
    uniqueName: uniqueName
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: searchPartitionCount
    publicNetworkAccess: searchPublicNetworkAccess
    replicaCount: searchReplicaCount
    sku: searchSkuName
    dataSourceName: 'sourceData'
    storageAcctName: 'storage${uniqueName}'
    containerName: containers[0]
  }
}

@description('Creates Log Analytics wkspace and related objects')
module analytics 'services/dashboard.bicep' = {
  scope: rg
  name: 'Analytics'
  params: {
    uniqueName: uniqueName
    tags: tags
    location: location
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

// module setupIndex 'scripts/searchSetup.bicep' = {
//   scope: rg
//   name: 'setupIndex'
//   params: {
//     location: location
//     uniqueName: uniqueName
//     searchName: 'search-${uniqueName}'
//     dataSourceName: 'sourceData'
//     storageAcctName: 'storage${uniqueName}'
//     containerName: containers[0]
//   }
// }

output aiEndpoint string = ai.outputs.endpoint
