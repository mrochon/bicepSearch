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

output searchIdentityId string = searchIdentityProvider.id
output searchIdentityPrincipalId string = searchIdentityProvider.properties.principalId
