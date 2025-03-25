targetScope = 'resourceGroup'
@description('The name of the user assigned identity.')
param name string
@description('The location of the resource group.')
param location string = resourceGroup().location
@description('The tags to apply to the resource.')
param tags object = {}


resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: name
  location: location
  tags: tags
}

@description('The ID of the user assigned identity.')
output id string = userAssignedIdentity.id

@description('The principal ID of the user assigned identity.')
output principalId string = userAssignedIdentity.properties.principalId
