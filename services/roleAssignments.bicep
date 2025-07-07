param aiFoundryName string
param searchPrincipalId string

var aiUser = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
resource aiContrAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryName, aiUser, searchPrincipalId)
  scope: resourceGroup()
  properties: {
    description: 'Cognitive Services OpenAI User'
    principalId: searchPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', aiUser)
  }
}
