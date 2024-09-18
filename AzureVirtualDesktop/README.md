## September 18 2024 Update
- Updated output hostpool token function to use the listfunction which allows newer versions of BICEP to output the hostpool token which is a secret.
- introduced keyvault into hostpool in case Microsoft breaks the secure output of hostpool again.
- Added existing keyvault so you can pull the secret from the keyvault.

# Azure Virtual Desktop Bicep
This guide provides simple instructions on how to use the Bicep modules to deploy an Azure Virtual Desktop (AVD) environment. The main file structures the deployment process, referencing different modules for specific resources.

## Main File Structure AVD BICEP modules
The main file defines the parameters and modules needed for the deployment. It sets up a resource group, virtual network, host pool, application group, workspace, virtual machine, AAD join, AVD agent, and necessary permissions. The modules are called sequentially, with dependencies specified to ensure the correct order of resource creation.

- Modules
Resource Group
File: Modules/resourceGroup.bicep
Description: Creates a resource group.

- Virtual Network
File: Modules/virtualNetwork.bicep
Description: Sets up a virtual network with specified subnets.

- Host Pool
File: Modules/hostPool.bicep
Description: Deploys a host pool for the AVD environment.

- Application Group
File: Modules/applicationGroups.bicep
Description: Creates an application group linked to the host pool.

- Workspace
File: Modules/workspace.bicep
Description: Creates a workspace and links it to the application group.

- Virtual Machine
File: Modules/virtualMachine.bicep
Description: Deploys a virtual machine with specified configurations.

- AAD Join
File: Modules/aadJoin.bicep
Description: Configures AAD join for the virtual machine.

- AVD Agent
File: Modules/avdAgent.bicep
Description: Installs the AVD agent on the virtual machine.

- Permissions
File: Modules/azureVirtualDesktopPermissions.bicep
Description: Assigns necessary roles to the principal.

Sample main file

```bicep
targetScope = 'subscription'

param tags object = {
  'deployed By': 'CyberCareerAcademy'
}

param date string = utcNow()

param location string = 'WestUs3'

param resourceGroupName string = 'rg-avd-prd-wus3'

//hostpool Params
param hostPoolName string = 'hp-avd-prd-wus3'

// applicationGroup Params
param applicationGroupName string = 'ag-avd-prd-wus3'

//Workspace Params 
param workspaceName string = 'ws-avd-prd-wus3'

// Virtual Network Parameters
param virtualNetworkName string = 'vnet-avd-prd-wus3'

param vnetCIDR string = '10.0.0.0/20'

param subnets array = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.1.0/24'
  }
]

// Virtual Machine params
param adminUsername string = 'azadmin'

param adminPassword string = '123!@#ABCabc'

param OSVersion string = '2022-datacenter-azure-edition'

param vmSize string = 'Standard_B4ms'

param vmName string = 'vm-avd-prd-01'

param securityType string = 'Standard'

module RG 'Modules/resourceGroup.bicep' = {
  name: '${resourceGroupName}-${date}'
  params: {
    location: location
    tags: tags
    resourceGroupName: resourceGroupName
  }
}

module virtualNetwork 'Modules/virtualNetwork.bicep' = {
  dependsOn: [
    RG
  ]
  name: '${virtualNetworkName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    tags: tags
    virtualNetworkName: virtualNetworkName
    subnets: subnets
    vnetCIDR: vnetCIDR
    location: location
  }
}

module hostpool 'Modules/hostPool.bicep' = {
  dependsOn: [
    RG
  ]
  name: '${hostPoolName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    hostPoolName: hostPoolName
    location: location
    tags: tags
  }
}

module applicationGroup 'Modules/applicationGroups.bicep' = {
  name: '${applicationGroupName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    applicationGroupName: applicationGroupName
    hostpoolId: hostpool.outputs.hostpoolId
  }
}

module workspace 'Modules/workspace.bicep' = {
  name: '${workspaceName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    tags: tags
    workspaceName: workspaceName
    applicationGroupId: applicationGroup.outputs.applicationGroupId
  }
}

module vm 'Modules/vmModule.bicep' = {
  name: '${vmName}-${date}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    sku: OSVersion
    securityType: securityType
    vmName: vmName
    vmSize: vmSize
    virtualNetworkName: virtualNetworkName
    subnetName: subnets[0].name
    hostpoolToken: hostpool.outputs.hostpoolToken
    hostpoolName: hostpool.outputs.hostpoolName
  }
}

module permissions 'Modules/azureVirtualDesktopPermissions.bicep' = {
  dependsOn: [
    RG
  ]
  name: 'AVDPermissions-${date}'
  params: {
    principalId: principalId
    principalType: 'User'
  }
}

module permissions 'Modules/azureVirtualDesktopPermissions.bicep' = {
  dependsOn: [
    RG
  ]
  name: 'AVDPermissions-${date}'
  params: {
    principalId: '728d27c2-46a8-494a-ad35-0ac2836f7ae8'
    principalType: 'User'
  }
}
```

Usage Instructions
Clone the Repository:

sh
Copy code
git clone <repository-url>
cd AzureLabs
Edit Parameters: Update the parameter values in the main.bicep file to match your environment.

Deploy: Use Azure CLI or Azure PowerShell to deploy the main Bicep file.

sh
Copy code
az deployment sub create --location <location> --template-file main.bicep
Monitor Deployment: Check the Azure Portal to monitor the deployment status and ensure all resources are created successfully.

By following these steps and using the provided modules, you can set up a comprehensive Azure Virtual Desktop environment tailored to your requirements.
