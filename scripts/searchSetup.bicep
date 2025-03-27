targetScope = 'resourceGroup'

param uniqueName string
param tags object = {}
param location string = resourceGroup().location
param rgName string = resourceGroup().name
param searchName string
param dataSourceName string
param storageAcctName string
param containerName string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'searchSetup'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '7.5.0'
    scriptContent: '''
$token = Get-AzAccessToken -ResourceUrl "https://search.azure.com/"
$headers = @{
  'Authorization' = "Bearer $($token.Token)"
  'Content-Type' = 'application/json'
}
$body = @"
{
      {
        "@odata.context": "https://$args[1].search.windows.net/`$metadata#datasources/`$entity",
        "@odata.etag": "\"0x8DC59AEA85B6E01\"",
        "name": "$args[2]",
        "description": "Tech documents.",
        "type": "azureblob",
        "credentials": {
          "connectionString": "ResourceId=/subscriptions/$args[5]/resourceGroups/$args[0]/providers/Microsoft.Storage/storageAccounts/$args[3];"
        },
        "container": {
          "name": "$containerName",
          "query": ""
        }
      }
}
"@
$url="https://$($args[1]).search.windows.net/datasources('$($args[2])')?allowIndexDowntime=True&api-version=2024-07-01"
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    arguments: '${rgName} ${searchName} ${dataSourceName} ${storageAcctName} ${containerName} ${subscription().subscriptionId}'
    retentionInterval: 'P1D'
  }
}

resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'script-${uniqueName}-identity'
  location: location
  tags: tags
}


output scriptIdentityPrincipalId string = scriptIdentity.properties.principalId
