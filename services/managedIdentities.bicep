targetScope = 'resourceGroup'

metadata description = 'Creates Managed Identities.'
param tags object = {}
param location string = resourceGroup().location
param searchManagedIdentityName string


resource searchIdentityProvider 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: searchManagedIdentityName
  location: location
  tags: tags
}

@description('Search user assigned identity name.')
output searchIdentityName string = searchIdentityProvider.name
@description('The ID of the user assigned identity.')
output searchIdentityId string = searchIdentityProvider.id
@description('The principal ID of the user assigned identity.')
output searchIdentityPrincipalId string = searchIdentityProvider.properties.principalId
