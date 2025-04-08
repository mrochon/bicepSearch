$SecurePassword = ConvertTo-SecureString -String ... -AsPlainText -Force
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
  "name": "techdoc3-datasource",
  "description": "Tech documents.",
  "type": "azureblob",
  "credentials": {
    "connectionString": "ResourceId=/subscriptions/7cee9002-39e6-44f8-a673-6f8680f8f4ad/resourceGroups/rg-bicepsearch3/providers/Microsoft.Storage/storageAccounts/storagegxq7lyngidvio;"
  },
  "container": {
    "name": "searchdata",
    "query": ""
  }
}
"@
# $url="https://$($args[1]).search.windows.net/datasources('$($args[2])')?allowIndexDowntime=True&api-version=2024-07-01"
$url="https://mrfunctions.azurewebsites.net/api/ReceiveCall?"
Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
"Completed with no error"


