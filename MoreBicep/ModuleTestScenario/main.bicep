param location string = 'westus3'
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}00'
param storageAccountSkuName string = 'Standard_LRS'
param whatDirection array = [
  'north'
  'south'
  'east'
  'west'
]
param whatElevation array = [
  'up'
  'down'
]

module storageAccountCompass 'modules/storage.bicep' = [for direction in whatDirection: {
  name: '${storageAccountName}${direction}'
  params: {
    location: location
    storageAccountName: '${storageAccountName}${direction}'
    storageAccountSkuName: storageAccountSkuName
  }
}]

module storageAccountElevation 'modules/storage.bicep' = [for elevation in whatElevation: {
  name: '${storageAccountName}${elevation}'
  params: {
    location: location
    storageAccountName: '${storageAccountName}${elevation}'
    storageAccountSkuName: storageAccountSkuName
  }
}]

/*
New-AzResourceGroupDeployment -TemplateFile main.bicep
*/
