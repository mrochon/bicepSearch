targetScope = 'subscription'

@minLength(6)
@maxLength(64)
@description('Name of the project. Part of resource group name. Also used to generate unique names for all resources.')
param projectName string

@minLength(1)
@description('Location for all resources')
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


@description('Container names. Use same names as the future index names.')
param containers array

@description('Model deployments for OpenAI. First deployment must be for embedding.')
@minLength(1)
param deployments array = [
  {
    name: 'text-embedding-3-small'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-small'
      version: '1'
    }
    sku : {
      name: 'Standard'
      capacity: 50
    }
  }
  {
    name: 'gpt-4.1-mini'
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1-mini'
      version: '2025-04-14'
    }
    sku : {
      name: 'GlobalStandard'
      capacity: 150
    }
  }  
]

var uniqueName = toLower(uniqueString(subscription().id, projectName))

var rgName = 'rg-${projectName}-${uniqueName}'
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tags
}

var searchManagedIdentityName = '${searchServiceName}-identity'
// A user assigned identity is required for by index definition
module managedIdentities 'services/managedIdentities.bicep' = {
  scope: rg
  name: 'managedIdentities'
  params: {
    tags: tags
    location: location
    searchManagedIdentityName: searchManagedIdentityName
  }
}

var foundryName = 'foundry-${uniqueName}'
module aiFoundry 'services/aiFoundry.bicep' = {
  scope: rg
  name: 'aiFoundry'
  params: {
    location: location
    aiFoundryName: foundryName
    aiProjectName: projectName
    deployments: deployments
  }
}

var storageName =   'storage${uniqueName}'
module storage 'services/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    tags: tags
    location: location
    storageName: storageName
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
    // searchSAIdentityPrincipalId: searchService.outputs.searchSAIdentityPrincipalId
    searchPrincipalId: searchService.outputs.searchSysAssignedPrincipalId    
  }
}

var searchServiceName = 'search-${uniqueName}'
@description('Creates an Azure AI Search service.')
module searchService 'services/search.bicep' = {
  scope: rg
  name:  'search'
  params: {
    tags: tags
    location: location
    serviceName: searchServiceName
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
    searchIdentityId: managedIdentities.outputs.searchIdentityId
    aiProjectPrincipalId: aiFoundry.outputs.aiProjectPrincipalId   
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

module roleAssignments 'services/roleAssignments.bicep' = {
  scope: rg
  name: 'roleAssignments'
  params: {
    aiFoundryName: foundryName
    searchPrincipalId: searchService.outputs.searchIdentityPrincipalId
  }
}

output projectName string = projectName
output subscriptionId string = subscription().id
output rgName string = rg.name
output searchName string = searchService.outputs.name
output searchEndpoint string = searchService.outputs.endpoint
output storageAcctName string = storage.outputs.name
output containers array = containers
output searchIdentityName string = managedIdentities.outputs.searchIdentityName
output openaiEndpoint string = 'https://${foundryName}.openai.azure.com'
output embeddingDeployment string = deployments[0].name
//output foundryEndpoints object = aiFoundry.outputs.endpoints


