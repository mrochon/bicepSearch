targetScope = 'resourceGroup'

metadata description = 'Creates Managed Identities.'
param tags object = {}
param location string = resourceGroup().location
param uniqueName string


resource searchIdentityProvider 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'search-${uniqueName}-identity'
  location: location
  tags: tags
}

resource aiIdentityProvider 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'ai-${uniqueName}-identity'
  location: location
  tags: tags
}

@description('Search user assigned identity name.')
output searchUAIdentityName string = searchIdentityProvider.name
@description('The ID of the user assigned identity.')
output searchUAIdentityId string = searchIdentityProvider.id
@description('The principal ID of the user assigned identity.')
output searchUAIdentityPrincipalId string = searchIdentityProvider.properties.principalId

output aiUAIdentityName string = aiIdentityProvider.name
output aiUAIdentityId string = aiIdentityProvider.id
output aiUAIdentityPrincipalId string = aiIdentityProvider.properties.principalId
