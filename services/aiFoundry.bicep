param aiFoundryName string 
param aiProjectName string 
param location string = 'eastus2'
param deployments array
param tags object = {}

/*
  An AI Foundry resources is a variant of a CognitiveServices/account resource type
*/ 
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: aiFoundryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true 
    customSubDomainName: aiFoundryName
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

/*
  Developer APIs are exposed via a project, which groups in- and outputs that relate to one use case, including files.
  Its advisable to create one project right away, so development teams can directly get started.
  Projects may be granted individual RBAC permissions and identities on top of what account provides.
*/ 
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [for deployment in deployments: {
  parent: aiFoundry
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: null
  }
  sku: deployment.sku
}]

/*
  Optionally deploy a model to use in playground, agents and other tools.
*/
// resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01'= {
//   parent: aiFoundry
//   name: 'gpt-4o'
//   sku : {
//     capacity: 1
//     name: 'GlobalStandard'
//   }
//   properties: {
//     model:{
//       name: 'gpt-4o'
//       format: 'OpenAI'
//     }
//   }
// }

output aiProjectPrincipalId string = aiProject.identity.principalId
output endpoint string = aiFoundry.properties.endpoint
output endpoints object = aiFoundry.properties.endpoints
