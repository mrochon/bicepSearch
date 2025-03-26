# $SecurePassword = Read-Host -Prompt 'Enter a Password' -AsSecureString
$searchName="search-storaget43soeccwpx5s"
$dataSourceName="datasource"
$storageAcctName="storaget43soeccwpx5s"
$containerName="searchdata"
$subscriptionId='7cee9002-39e6-44f8-a673-6f8680f8f4ad'
$rgName="rg-bicepsearch2"

$SecurePassword = ConvertTo-SecureString -String '...' -AsPlainText -Force
$TenantId = '1165490c-89b5-463b-b203-8b77e01597d2'
$ApplicationId = 'e3f2418a-8ca5-4d48-864c-1a6819cfe650'
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword

Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential -SubscriptionId '7cee9002-39e6-44f8-a673-6f8680f8f4ad'
$token = Get-AzAccessToken -ResourceUrl "https://search.azure.com/"
$headers = @{
  'Authorization' = "Bearer $($token.Token)"
  'Content-Type' = 'application/json'
}
$body = @"
{
      {
        "@odata.context": "https://$searchName.search.windows.net/$metadata#datasources/$entity",
        "@odata.etag": "\"0x8DC59AEA85B6E01\"",
        "name": "$dataSourceName",
        "description": "Tech documents.",
        "type": "azureblob",
        "credentials": {
          "connectionString": "ResourceId=/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageAcctName;"
        },
        "container": {
          "name": "$containerName",
          "query": ""
        }
      }
}
"@
$url="https://$searchName.search.windows.net/datasources('{0}')?allowIndexDowntime=True&api-version=2024-07-01" -f $dataSourceName
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
