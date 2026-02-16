param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [string]$SubscriptionId,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if ($SubscriptionId) {
    Write-Host "Setting subscription to $SubscriptionId"
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Purging soft-deleted resources for resource group: $ResourceGroupName"

$providers = @(
    'Microsoft.KeyVault/vaults',
    'Microsoft.AppConfiguration/configurationStores',
    'Microsoft.CognitiveServices/accounts',
    'Microsoft.Storage/storageAccounts'
)

$resources = az resource list --resource-group $ResourceGroupName --query "[].{id:id, type:type, name:name, location:location}" | ConvertFrom-Json
$targets = @($resources | Where-Object { $providers -contains $_.type })

if ($targets.Count -eq 0) {
    Write-Host "No matching resources found."
    return
}

Write-Host "Resources to purge:"
foreach ($target in $targets) {
    Write-Host " - $($target.type) $($target.name) ($($target.location))"
}

if ($DryRun) {
    Write-Host "Dry run enabled. No changes were made."
    return
}

if (-not $Force) {
    $confirmation = Read-Host "Type PURGE to continue"
    if ($confirmation -ne 'PURGE') {
        Write-Host "Confirmation not received. Aborting."
        return
    }
}

foreach ($resource in $targets) {

    Write-Host "Processing $($resource.type) $($resource.name) in $($resource.location)"

    if ($resource.type -eq 'Microsoft.KeyVault/vaults') {
        az keyvault delete --name $resource.name --resource-group $ResourceGroupName | Out-Null
        az keyvault purge --name $resource.name --location $resource.location | Out-Null
        continue
    }

    if ($resource.type -eq 'Microsoft.AppConfiguration/configurationStores') {
        az appconfig delete --name $resource.name --resource-group $ResourceGroupName --yes | Out-Null
        az resource delete --ids $resource.id | Out-Null
        continue
    }

    if ($resource.type -eq 'Microsoft.CognitiveServices/accounts') {
        $projectIds = az resource list --resource-group $ResourceGroupName --resource-type "Microsoft.CognitiveServices/accounts/projects" --query "[?contains(id, '/accounts/$($resource.name)/')].id" -o tsv
        foreach ($projectId in $projectIds) {
            Write-Host "  Deleting project $projectId"
            az resource delete --ids $projectId | Out-Null
        }

        $deployments = az cognitiveservices account deployment list --name $resource.name --resource-group $ResourceGroupName | ConvertFrom-Json
        foreach ($deployment in $deployments) {
            Write-Host "  Deleting deployment $($deployment.name)"
            az cognitiveservices account deployment delete --name $resource.name --resource-group $ResourceGroupName --deployment-name $deployment.name | Out-Null
        }
        az cognitiveservices account delete --name $resource.name --resource-group $ResourceGroupName | Out-Null
        az resource delete --ids $resource.id | Out-Null
        continue
    }

    if ($resource.type -eq 'Microsoft.Storage/storageAccounts') {
        az storage account delete --name $resource.name --resource-group $ResourceGroupName --yes | Out-Null
        az resource delete --ids $resource.id | Out-Null
        continue
    }
}

Write-Host "Purge completed."
