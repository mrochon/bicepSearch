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

@description('Whether to disable local authentication')
param searchDisableLocalAuth bool = false

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
    containers: [
      {
        name: 'searchdata'
      }
    ]
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: true
    allowSharedKeyAccess: false
    corsRules: []
    defaultToOAuthAuthentication: false
    deleteRetentionPolicy: {}
    dnsEndpointType: 'Standard'
    files: []
    isHnsEnabled: false
    kind: 'StorageV2'
    minimumTlsVersion: 'TLS1_2'
    queues: []
    shareDeleteRetentionPolicy: {}
    supportsHttpsTrafficOnly: true
    searchManagedIdentityId: searchService.outputs.identityId
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
  }
}

@description('Creates an Azure AI Search service.')
module searchService 'services/search.bicep' = {
  scope: rg
  name:  'search'
  params: {
    tags: tags
    location: location
    name: 'storage${uniqueName}'
    authOptions: {}
    disableLocalAuth: searchDisableLocalAuth
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


output aiEndpoint string = ai.outputs.endpoint
