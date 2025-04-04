function InvokeWithRetry($url, $headers, $body) {
    try {  
      Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $body
    } catch {
      $errorJson = @{
        error = $_.Exception.Message
      } | ConvertTo-Json
      $retryUrl = "https://mrfunctions.azurewebsites.net/api/ReceiveCall?"
      Invoke-RestMethod -Uri $retryUrl -Method PUT -Headers $headers -Body $errorJson  
      Invoke-RestMethod -Uri $retryUrl -Method PUT -Headers $headers -Body $body
      throw $_
    }
  }    
  $token = "abc"
  $headers = @{
    'Authorization' = "Bearer $($token.Token)"
    'Content-Type' = 'application/json'
  }
  
  $body = @{
    prop1 = "test"
  } | ConvertTo-Json
  $url="https://mrsearch.search.windows.net/datasources('xyz-datasource')?allowIndexDowntime=True&api-version=2024-07-01"
  InvokeWithRetry $url $headers $body