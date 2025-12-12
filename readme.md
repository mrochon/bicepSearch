## AI Search basic deployment bicep

### Purpose

Deploy AI Search and related infrastructure needed to create vectorized index (OpenAI for embedding and Storage Account for
document source). Includes deployment of index, indexer, data source and skillset definitions.

### Deployed architecture

This deployment creates the following objects:

- Resource group
- AI Search instance with:
-- Datasource
-- Index
-- Indexer
-- Skillset
-- Synonym Map
- Storage Account with:
-- Blob container (used by the above Data Source_)
- Cognitive Service instance with:
-- text-embedding-003-small model deployment (used by above Skillset)
- Managed Identities to manage access between these objects.
- Role assignments

![Architecture](docs/architecture.png)

### Setup

1. In the **json** folder, edit json definitions of your index, indexer, skillset, synonym map and data source. Do not modify the capitalized strings (e.g. PROJECT_NAME). Their values will be set by your bicep parameters.
2. Run **main.bicep** deployment

```Bash
az login [--tenant <domain>]
az deployment sub create --name searchDeployment \
  --template-file main.bicep \
  --parameters @main.parameters.json \
  --location 'eastus' \
  --subscription '7cee9002-39e6-44f8-a673-6f8680f8f4ad' \
  --query properties.outputs > bicepOutput.json
```

```
az deployment sub delete --name rg-searchbicep2
```

```
az deployment subscription show \
  --subscription '7cee9002-39e6-44f8-a673-6f8680f8f4ad' \
  --name bicepsearch2 \
  --query properties.outputs

az deployment group show \
  --resource-group rg-bicepsearch \
  --name bicepsearch2 
```

### Debugging

PowerShell script contained in **deploymentScripts** will attempt to create the AI Search artifacts based on your definitions in the **json** folder. Errors will be send to a REST endpoint included in the script. Replace it with your own if you bicep reports script errors so you can determine causes.

Following source is an example of such a function that may be deployed to Azure Functions.

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

### Notes

1. To upload sample data (e.g. [Health Plan pdfs](https://github.com/Azure-Samples/azure-search-sample-data/tree/main/health-plan) using Azure portal, make sure to give yourself Storgae Bloab Data Contributor role.

2. To execute searches from the Azure portal, give yourself Search Index Data Reader role.