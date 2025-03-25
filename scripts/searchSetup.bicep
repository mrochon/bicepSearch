param location string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'searchSetup'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.5.0'
    scriptContent: '''
      Write-Output "Hello, World!"
      # Add your PowerShell code here
    '''
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    arguments: '-Argument1 value1 -Argument2 value2'
    retentionInterval: 'P1D'
  }
}

output scriptOutput string = deploymentScript.properties.outputs.output
