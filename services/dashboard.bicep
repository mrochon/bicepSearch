targetScope = 'resourceGroup'

@minLength(6)
param uniqueName string
param location string = resourceGroup().location
param tags object = {}
param retentionInDays int = 30
param workspaceCapping object = {
  dailyQuotaGb: -1
}

resource analyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'la-${uniqueName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: retentionInDays
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: workspaceCapping
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Query Pack for Search Metrics
resource queryPack 'Microsoft.OperationalInsights/querypacks@2023-09-01' = {
  name: 'qp-${uniqueName}'
  location: location
  tags: tags
  properties: {}
}

// Search Status Codes Query
resource searchStatusCodesQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: '59f8102a-8b0a-4dad-924a-ec5333a9635d'
  properties: {
    displayName: 'Search Status Codes'
    body: 'let _startTime=datetime(\'2025-02-25T00:00:07Z\');\nlet _endTime=datetime(\'2026-03-03T00:00:07Z\');\nAzureDiagnostics\n| where TimeGenerated between([\'_startTime\'] .. [\'_endTime\']) // Time range filtering\n| summarize count() by status_code = resultSignature_d \n| render barchart'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

// Average Query Latency Query
resource avgQueryLatencyQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: '92aa369a-39b0-46ee-8cdc-03263193e136'
  properties: {
    displayName: 'Average Query Latency'
    body: 'let intervalsize = 1m; \nlet _startTime=datetime(\'2025-02-25T00:00:07Z\');\nlet _endTime=datetime(\'2026-03-03T00:00:07Z\');\nAzureDiagnostics\n| where TimeGenerated between([\'_startTime\']..[\'_endTime\']) // Time range filtering\n| summarize AverageQueryLatency = avgif(DurationMs, OperationName in ("Query.Search", "Query.Suggest", "Query.Lookup", "Query.Autocomplete"))\n    by bin(TimeGenerated, intervalsize)\n| render timechart\n'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

// Throttling Query
resource throttlingQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: 'ab1879f1-3289-47d3-919b-e3f6a46bf933'
  properties: {
    displayName: 'metric-throttling'
    description: 'Throttling over the queries or indexing process. Throttled queries correlated with the times in with the performance benchmarking was performed.'
    body: 'let [\'_startTime\']=datetime(\'2025-02-25T00:00:07Z\');\nlet [\'_endTime\']=datetime(\'2026-03-03T00:00:07Z\');\nlet intervalsize = 1m; \nAzureDiagnostics \n| where TimeGenerated > ago(7d)\n| where resultSignature_d != 403\n    and resultSignature_d != 404\n    and OperationName in ("Query.Search", "Query.Suggest", "Query.Lookup", "Query.Autocomplete")\n| summarize \n    ThrottledQueriesPerMinute=bin(countif(OperationName in ("Query.Search", "Query.Suggest", "Query.Lookup", "Query.Autocomplete") and resultSignature_d == 503) / (intervalsize / 1m), 0.01)\n    by bin(TimeGenerated, intervalsize)\n| render timechart\n'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

// Query Rates Query
resource queryRatesQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: 'd0713845-d2e7-41d9-88f3-7a582f5723bf'
  properties: {
    displayName: 'Query Rates'
    body: 'AzureDiagnostics\n| where OperationName == "Query.Search" and TimeGenerated > ago(1d)\n| extend MinuteOfDay = substring(TimeGenerated, 0, 16) \n| project MinuteOfDay, DurationMs, Documents_d, IndexName_s\n| summarize QPM=count(), AvgDuractionMs=avg(DurationMs), AvgDocCountReturned=avg(Documents_d)  by MinuteOfDay\n| order by MinuteOfDay desc \n| render timechart'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

// Indexing Operations Per Minute Query
resource indexingOpmQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: 'e37b471c-1f67-47e9-8aea-52d574a82f8c'
  properties: {
    displayName: 'Indexing Operations Per Minute (OPM)'
    body: 'let intervalsize = 1m; \nlet _startTime=datetime(\'2025-02-25T00:00:07Z\');\nlet _endTime=datetime(\'2026-03-03T00:00:07Z\');\nAzureDiagnostics\n| where TimeGenerated between([\'_startTime\'] .. [\'_endTime\']) // Time range filtering\n| summarize IndexingOperationsPerSecond=bin(countif(OperationName == "Indexing.Index")/ (intervalsize/1m), 0.01)\n  by bin(TimeGenerated, intervalsize)\n| render timechart\n\n'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

// Average Queries Per Minute Query
resource avgQpmQuery 'Microsoft.OperationalInsights/querypacks/queries@2023-09-01' = {
  parent: queryPack
  name: 'f08f71ab-3f02-473d-b76a-4b378be9c00d'
  properties: {
    displayName: 'Average Queries Per Minute (QPM)'
    body: 'let intervalsize = 1m; \nlet _startTime=datetime(\'2025-02-25T00:00:07Z\');\nlet _endTime=datetime(\'2026-03-03T00:00:07Z\');\nAzureDiagnostics\n| where TimeGenerated between([\'_startTime\'] .. [\'_endTime\']) // Time range filtering\n| summarize QueriesPerMinute=bin(countif(OperationName in ("Query.Search", "Query.Suggest", "Query.Lookup", "Query.Autocomplete"))/(intervalsize/1m), 0.01)\n  by bin(TimeGenerated, intervalsize)\n| render timechart'
    related: {
      categories: []
      resourceTypes: [
        'microsoft.search/searchservices'
      ]
    }
    tags: {
      labels: []
    }
  }
}

