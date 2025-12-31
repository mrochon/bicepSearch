#Requires -Modules Az.Accounts

param(
    [string]$IndexName,
    [string]$IndexDefinitionsPath = "./indexDefinitions",
    [string]$BicepOutputPath = "./bicepOutput.json",
    [switch]$GenerateOnly,
    [string]$OutputPath = "./tmp"
)

<#
.SYNOPSIS
Creates an Azure AI Search index with datasource, skillset, and indexer.

.DESCRIPTION
The New-SearchIndex cmdlet creates a complete Azure AI Search index configuration including:
- Data source connection
- Index schema
- Skillset for AI enrichment
- Indexer for data ingestion

.PARAMETER IndexName
The name of the index to create. Must match a folder name under ./indexDefinitions/.

.PARAMETER IndexDefinitionsPath
The path to the folder containing index definitions. Defaults to "./indexDefinitions".

.PARAMETER BicepOutputPath
The path to the Bicep output JSON file containing deployment information. Defaults to "./bicepOutput.json".

.PARAMETER GenerateOnly
When specified, generates the API request files without executing them.

.PARAMETER OutputPath
The path where generated files will be saved when using -GenerateOnly. Defaults to "./tmp".

.EXAMPLE
New-SearchIndex -IndexName "recipes"
Creates the recipes index using definitions from ./indexDefinitions/recipes/

.EXAMPLE
New-SearchIndex -IndexName "sops" -GenerateOnly
Generates the API request files for the sops index without executing them.

.EXAMPLE
New-SearchIndex -IndexName "sample" -BicepOutputPath "../bicepOutput.json"
Creates the sample index using a custom Bicep output file location.
#>

# Load required assemblies
Add-Type -AssemblyName 'System.Net.Http'
try {
    Add-Type -Path ([System.IO.Path]::Combine((Split-Path (Get-Module Az.Accounts -ListAvailable | Select-Object -First 1).Path), 'Azure.Core.dll'))
    Add-Type -Path ([System.IO.Path]::Combine((Split-Path (Get-Module Az.Accounts -ListAvailable | Select-Object -First 1).Path), 'Azure.Identity.dll'))
}
catch {
    # Fallback: try to use types if already loaded
    Write-Verbose "Azure assemblies may already be loaded or using alternative method"
}

function New-SearchIndex {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IndexName,
        
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$IndexDefinitionsPath = "./indexDefinitions",
        
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$BicepOutputPath = "../bicepOutput.json",
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateOnly,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "./tmp"
    )
    
    begin {
        Write-Verbose "Starting New-SearchIndex cmdlet"
        
        # Validate index definitions path exists
        $indexPath = Join-Path $IndexDefinitionsPath $IndexName
        if (-not (Test-Path -Path $indexPath -PathType Container)) {
            throw "Index definition path '$indexPath' does not exist."
        }
        
        # Load Bicep output
        Write-Verbose "Loading Bicep output from: $BicepOutputPath"
        $bicepOutput = Get-Content -Path $BicepOutputPath -Raw | ConvertFrom-Json
        
        # Get access token
        Write-Verbose "Acquiring Azure access token"
        try {
            # Try using Az.Accounts (more reliable)
            $token = (Get-AzAccessToken -ResourceUrl "https://search.azure.com").Token
            Write-Verbose "Successfully acquired token using Az.Accounts"
        }
        catch {
            Write-Verbose "Az.Accounts method failed, trying DefaultAzureCredential"
            try {
                # Fallback to DefaultAzureCredential
                $credential = New-Object Azure.Identity.DefaultAzureCredential
                $tokenRequestContext = New-Object Azure.Core.TokenRequestContext
                $tokenRequestContext.Scopes = @("https://search.azure.com/.default")
                $accessToken = $credential.GetToken($tokenRequestContext, [System.Threading.CancellationToken]::None)
                $token = $accessToken.Token
                Write-Verbose "Successfully acquired token using DefaultAzureCredential"
            }
            catch {
                throw "Failed to acquire access token. Please ensure you are logged in with 'az login' or 'Connect-AzAccount'. Error: $($_.Exception.Message)"
            }
        }
        
        $headers = @{
            'Authorization' = "Bearer $token"
            'Content-Type'  = 'application/json'
        }
        
        # Helper function to invoke REST API with retry logic
        function Invoke-SearchApiWithRetry {
            param(
                [string]$Url,
                [hashtable]$Headers,
                [string]$Body,
                [string]$Description
            )
            
            try {
                if ($GenerateOnly) {
                    if (-not (Test-Path -Path $OutputPath)) {
                        New-Item -Path $OutputPath -ItemType Directory | Out-Null
                    }
                    $output = @{
                        description = $Description
                        url         = $Url
                        headers     = $Headers
                        body        = ($Body | ConvertFrom-Json | ConvertTo-Json -Depth 10)
                    } | ConvertTo-Json -Depth 10
                    
                    $fileName = Join-Path $OutputPath "$($IndexName)_$Description`_$(Get-Random).json"
                    Set-Content -Path $fileName -Value $output
                    Write-Information "Generated file: $fileName" -InformationAction Continue
                    return $null
                }
                
                if ($PSCmdlet.ShouldProcess($Description, "Create")) {
                    Write-Verbose "Invoking API: $Url"
                    $response = Invoke-RestMethod -Uri $Url -Method PUT -Headers $Headers -Body $Body
                    return $response
                }
            }
            catch {
                $errorDetails = @{
                    error       = $_.Exception.Message
                    url         = $Url
                    description = $Description
                }
                Write-Error "Failed to create $Description`: $($_.Exception.Message)"
                Write-Verbose ($errorDetails | ConvertTo-Json)
                throw
            }
        }
        
        # Helper function to update body with deployment values
        function Update-RequestBody {
            param(
                [string]$Body,
                [string]$IndexName,
                [object]$BicepOutput
            )
            
            $Body = $Body -replace 'INDEX_NAME', $IndexName
            $Body = $Body -replace 'SUBSCRIPTION_ID', $BicepOutput.subscriptionId.value
            $Body = $Body -replace 'RESOURCEGROUP_NAME', $BicepOutput.rgName.value
            $Body = $Body -replace 'STORAGEACCOUNT_NAME', $BicepOutput.storageAcctName.value
            $Body = $Body -replace 'CONTAINER_NAME', $IndexName
            $Body = $Body -replace 'OPENAI_ENDPOINT', $BicepOutput.openaiEndpoint.value
            $Body = $Body -replace 'SEARCH_IDENTITY_NAME', $BicepOutput.searchIdentityName.value
            $Body = $Body -replace 'EMBEDDING_DEPLOYMENT_NAME', $BicepOutput.embeddingDeployment.value
            
            return $Body
        }
    }
    
    process {
        $apiVersion = "2025-09-01"
        $searchEndpoint = "https://$($bicepOutput.searchName.value).search.windows.net"
        
        # Create datasource
        Write-Information "Creating datasource for index: $IndexName" -InformationAction Continue
        $dataSourcePath = Join-Path $indexPath "dataSource.json"
        if (Test-Path $dataSourcePath) {
            $body = Get-Content -Path $dataSourcePath -Raw
            $body = Update-RequestBody -Body $body -IndexName $IndexName -BicepOutput $bicepOutput
            $url = "$searchEndpoint/datasources('$($IndexName)-datasource')?allowIndexDowntime=True&api-version=$apiVersion"
            Invoke-SearchApiWithRetry -Url $url -Headers $headers -Body $body -Description "datasource"
        }
        else {
            Write-Warning "Data source file not found: $dataSourcePath"
        }
        
        # Create index
        Write-Information "Creating index: $IndexName" -InformationAction Continue
        $indexFilePath = Join-Path $indexPath "index.json"
        if (Test-Path $indexFilePath) {
            $body = Get-Content -Path $indexFilePath -Raw
            $body = Update-RequestBody -Body $body -IndexName $IndexName -BicepOutput $bicepOutput
            $url = "$searchEndpoint/indexes('$($IndexName)-index')?allowIndexDowntime=True&api-version=$apiVersion"
            Invoke-SearchApiWithRetry -Url $url -Headers $headers -Body $body -Description "index"
        }
        else {
            Write-Warning "Index file not found: $indexFilePath"
        }
        
        # Create skillset
        Write-Information "Creating skillset for index: $IndexName" -InformationAction Continue
        $skillsetPath = Join-Path $indexPath "skillset.json"
        if (Test-Path $skillsetPath) {
            $body = Get-Content -Path $skillsetPath -Raw
            $body = Update-RequestBody -Body $body -IndexName $IndexName -BicepOutput $bicepOutput
            $url = "$searchEndpoint/skillsets('$($IndexName)-skillset')?allowIndexDowntime=True&api-version=$apiVersion"
            Invoke-SearchApiWithRetry -Url $url -Headers $headers -Body $body -Description "skillset"
        }
        else {
            Write-Warning "Skillset file not found: $skillsetPath"
        }
        
        # Create indexer
        Write-Information "Creating indexer for index: $IndexName" -InformationAction Continue
        $indexerPath = Join-Path $indexPath "indexer.json"
        if (Test-Path $indexerPath) {
            $body = Get-Content -Path $indexerPath -Raw
            $body = $body -replace 'INDEX_NAME', $IndexName
            $url = "$searchEndpoint/indexers('$($IndexName)-indexer')?allowIndexDowntime=True&api-version=$apiVersion"
            Invoke-SearchApiWithRetry -Url $url -Headers $headers -Body $body -Description "indexer"
        }
        else {
            Write-Warning "Indexer file not found: $indexerPath"
        }
    }
    
    end {
        Write-Information "Index creation completed for: $IndexName" -InformationAction Continue
    }
}

# Allow script to be run directly or imported as a module
if ($MyInvocation.InvocationName -ne '.') {
    New-SearchIndex @PSBoundParameters
}