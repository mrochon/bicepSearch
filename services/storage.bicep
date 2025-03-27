targetScope = 'resourceGroup'
metadata description = 'Creates an Azure storage account.'
param name string
param location string = resourceGroup().location
param tags object = {}
@description('The list of blob containers to create in the storage account.')
@minLength(1)
param containers array

@allowed([
  'Cool'
  'Hot'
  'Premium' ])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = false
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = false
param corsRules array = []
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed([ 'AzureDnsZone', 'Standard' ])
param dnsEndpointType string = 'Standard'
param isHnsEnabled bool = false
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param supportsHttpsTrafficOnly bool = true
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param sku object = { name: 'Standard_LRS' }

param searchManagedIdentityPrincipalId string

var storage_name = 'storage${name}'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storage_name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    isHnsEnabled: isHnsEnabled
    minimumTlsVersion: minimumTlsVersion
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {
      cors: {
        corsRules: corsRules
      }
      deleteRetentionPolicy: deleteRetentionPolicy
    }
    resource container 'containers' = [for container in containers: {
      name: container
      properties: {
        publicAccess: 'None'
      }
    }]
  }

  // resource fileServices 'fileServices' = if (!empty(files)) {
  //   name: 'default'
  //   properties: {
  //     cors: {
  //       corsRules: corsRules
  //     }
  //     shareDeleteRetentionPolicy: shareDeleteRetentionPolicy
  //   }
  // }

  // resource queueServices 'queueServices' = if (!empty(queues)) {
  //   name: 'default'
  //   properties: {

  //   }
  //   resource queue 'queues' = [for queue in queues: {
  //     name: queue.name
  //     properties: {
  //       metadata: {}
  //     }
  //   }]
  // }

  // resource tableServices 'tableServices' = if (!empty(tables)) {
  //   name: 'default'
  //   properties: {}
  // }
}

resource search2StorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('searchcontainer', searchManagedIdentityPrincipalId, '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
  scope: storage::blobServices::container[0]
  properties: {
    //delegatedManagedIdentityResourceId: searchManagedIdentityId
    description: 'Blob Reader role assignment for Search service'
    principalId: searchManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
  }
}

output id string = storage.id
output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
output resource object = storage
output resourceName string = storage.name
