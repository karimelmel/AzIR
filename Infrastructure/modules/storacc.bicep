param location string

var storageAccountName = 'psazir${uniqueString(resourceGroup().id)}'

var blobServicesName = 'default'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: blobServicesName
}


resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'artifacts'
  parent: storageAccountBlobServices
  properties: {
  }
}

output storAcc object = storageAccount
output storAccName string = storageAccount.name
