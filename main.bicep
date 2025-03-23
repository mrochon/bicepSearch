targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the project. Used to generate unique names for all resources.')
param projectName string

@minLength(1)
@description('Primary location for all resources')
param location string

var resourceGroupName  = 'rg-${projectName}'
var uniqueName = toLower(uniqueString(subscription().id, projectName, location))

var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': projectName
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

@description('Creates an Azure AI services.')
module ai 'services/ai.bicep' = {
  scope: rg
  name: 'ai-${uniqueName}'
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
    name: uniqueName
    authOptions: {}
    disableLocalAuth: false
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
  }
}

output endpoint string = ai.outputs.endpoint
