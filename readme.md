## Deployment

```
az deployment sub create --location 'eastus' --name 'searchbicep2' --paramaters main.parameters.json --template-file main.bicep 
```

```
az deployment sub delete --name searchbicep2
```