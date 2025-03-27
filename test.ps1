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
$body = @{
  name = $args[2]
  description = "Tech documents."
  type = "azureblob"
  credentials = @{
    connectionString = "ResourceId=/subscriptions/$($args[5])/resourceGroups/$($args[0])/providers/Microsoft.Storage/storageAccounts/$($args[3]);"
  }
  container = @{
    name = $args[4]
    query = ""
  }
}
$jsonBody = $body | ConvertTo-Json -Depth 10
$url="https://$($args[1]).search.windows.net/datasources('$($args[2])')?allowIndexDowntime=True&api-version=2024-07-01"
#Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $jsonBody
echo "Completed with no error"


