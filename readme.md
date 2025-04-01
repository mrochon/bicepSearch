## Setup

Populate ./json folder with definitions of AI Search REST payloads.

## Execution

```
az deployment sub create --name bicespsearch2 \
  --template-file main.bicep \
  --parameters @main.parameters.json \
  --location 'eastus' \
  --subscription '7cee9002-39e6-44f8-a673-6f8680f8f4ad'

```

```
az deployment sub delete --name rg-searchbicep2
```

```
./test.ps1 'rg-bicepsearch2' 'search-t43soeccwpx5s' datasource storaget43soeccwpx5s searchdata '7cee9002-39e6-44f8-a673-6f8680f8f4ad'
```

```
$url="https://$($env:searchName).search.windows.net/datasources('$($env:dataSourceName)')?allowIndexDowntime=True&api-version=2024-07-01"
```

## Debugging

To debug possible errors in the script components of the bicep calling http REST services, use an Azure Function to display request details in log file.
Replace the call to the REST service with a call to this function, with same parameters and body.
You can then replicate the call to the original service to see what errors it returns.

```
curl -X POST -H "Content-Type: application/json" -d '{"key1":"value1", "key2":"value2"}' https://mrfunctions.azurewebsites.net/api/ReceiveCall?
```

```C#
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace MR.Function
{
    public class ReceiveCall
    {
        private readonly ILogger<ReceiveCall> _logger;

        public ReceiveCall(ILogger<ReceiveCall> logger)
        {
            _logger = logger;
        }

        [Function("ReceiveCall")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", "put")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            // List all headers
            foreach (var header in req.Headers)
            {
                _logger.LogInformation($"Header: {header.Key} = {header.Value}");
            }
            // Log all query parameters
            foreach (var query in req.Query)
            {
                _logger.LogInformation($"Query Parameter: {query.Key} = {query.Value}");
            }
            var body = req.Body;
            using (var reader = new StreamReader(body))
            {
                var requestBody = reader.ReadToEndAsync().Result;
                _logger.LogInformation($"Request Body: {requestBody}");
            }
            return new OkObjectResult("Welcome to Azure Functions!");
        }
    }
}

```