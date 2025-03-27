## Deployment

```
az deployment sub create --name bicespsearch2 \
  --template-file main.bicep \
  --parameters @main.parameters.json \
  --location 'eastus' \
  --subscription '7cee9002-39e6-44f8-a673-6f8680f8f4ad'

```

```
az deployment sub delete --name searchbicep2
```

```
./test.ps1 'rg-bicepsearch2' 'search-t43soeccwpx5s' datasource storaget43soeccwpx5s searchdata '7cee9002-39e6-44f8-a673-6f8680f8f4ad'
```