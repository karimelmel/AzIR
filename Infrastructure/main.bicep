targetScope = 'subscription'

@description('Sets the time now to concatenate the string in the deployment name with a unqiue value.')
param dateTime string = utcNow()

@description('Name of Resource Group that will be created. Defaults to a predefined value')
param resourceGroupName string = ''

@description('Id of the Subscription the Resources will be provisioned in e.g. 00000000-0000-0000-0000-000000000000')
param subscriptionId string = ''

@description('Name of the region where the resources are deployed. (e.g.: westeurope)')
param location string = ''

@description('Object Id of the Entra ID group you want to assign permissions')
param entraIDGroupObjectId string = ''

param roleDefinitionId string = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'


module resourceGrp './modules/resourcegrp.bicep' = {
  name: 'resourceGroup-psazir-${dateTime}'
  scope: subscription(subscriptionId) 
  params: {
    resourceGroupName: resourceGroupName
    location: location
  }
}

module storacc 'modules/storacc.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'storaccDeployment-psazir-${dateTime}'
  params: {
    location: location
  }
  dependsOn: [
    resourceGrp
  ]
}

module roleAssignment 'modules/roleassignment.bicep' = {
  name: 'role-assignment-${dateTime}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    storAccName: storacc.outputs.storAccName
    location: location
    principalId: entraIDGroupObjectId
    roleDefinitionId: roleDefinitionId
  }
  dependsOn: [
    storacc
  ]
}

