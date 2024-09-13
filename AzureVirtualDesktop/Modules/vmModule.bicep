@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02705.330.zip'

@description('The availability option for the VMs.')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'None'

@description('The name of availability set to be used when create the VMs.')
param availabilitySetName string = ''

@description('The availability zones to equally distribute VMs amongst')
param availabilityZones array = []

@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param offer string = 'windows-10'

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param publisher string = 'microsoftwindowsdesktop'

@description('Whether the VM image has a plan or not')
param vmGalleryImageHasPlan bool = false

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param sku string = 'win10-22h2-avd'

@description('(Required when vmImageType = Gallery) Gallery image version.')
param vmGalleryImageVersion string = ''

param vmName string

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param rdshPrefix string = take(toLower(resourceGroup().name), 10)

@description('The VM disk type for the VM: HDD or SSD.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param storageAccountType string = 'StandardSSD_LRS'

@description('The size of the session host VMs.')
param vmSize string = 'Standard_A2'

@description('The size of the disk on the vm in GB')
param rdshVmDiskSizeGB int = 128

@description('Whether or not the VM is hibernate enabled')
param rdshHibernate bool = false

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs.')
param enableAcceleratedNetworking bool = false

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by adminUsername and adminPassword will be used.')
param adminUsername string = ''

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by adminUsername and adminPassword will be used.')
@secure()
param adminPassword string = ''

param virtualNetworkName string

param subnetName string

@description('The unique id of the load balancer backend pool id for the nics.')
param loadBalancerBackendPoolId string = ''

@description('Location for all resources to be created in.')
param location string = ''

@description('The EdgeZone extended location of the session host VMs.')
param extendedLocation object = {}

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The tags to be assigned to the network interfaces')
param networkInterfaceTags object = {}

@description('The tags to be assigned to the virtual machines')
param virtualMachineTags object = {}

param _guidValue string = newGuid()

@description('The token for adding VMs to the hostpool')
@secure()
param hostpoolToken string?

@description('The name of the hostpool')
param hostpoolName string

@description('Domain to join')
param domain string = ''

param avdAgent bool = true

param hostpoolid string?

@description('IMPORTANT: You can use this parameter for the test purpose only as AAD Join is public preview. True if AAD Join, false if AD join')
param aadJoin bool = true

@description('IMPORTANT: Please don\'t use this parameter as intune enrollment is not supported yet. True if intune enrollment is selected.  False otherwise')
param intune bool = false

@description('Boot diagnostics object taken as body of Diagnostics Profile in VM creation')
param bootDiagnostics object = {
  enabled: false
}

@description('The name of user assigned identity that will assigned to the VMs. This is an optional parameter.')
param userAssignedIdentity string = ''

@description('The PowerShell script URL to be run as part of post update custom configuration')
param customConfigurationScriptUrl string = ''

@description('Session host configuration version of the host pool.')
param SessionHostConfigurationVersion string = ''

@description('System data is used for internal purposes, such as support preview features.')
param systemData object = {}

@description('Specifies the SecurityType of the virtual machine. It is set as TrustedLaunch to enable UefiSettings. Default: UefiSettings will not be enabled unless this property is set as TrustedLaunch.')
@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
param securityType string = 'Standard'

@description('Specifies whether secure boot should be enabled on the virtual machine.')
param secureBoot bool = false

@description('Specifies whether vTPM (Virtual Trusted Platform Module) should be enabled on the virtual machine.')
param vTPM bool = false

@description('Specifies whether integrity monitoring will be added to the virtual machine.')
param integrityMonitoring bool = false

@description('Managed disk security encryption type.')
@allowed([
  'VMGuestStateOnly'
  'DiskWithVMGuestState'
])
param managedDiskSecurityEncryptionType string = 'VMGuestStateOnly'

var newNsgName = '${rdshPrefix}nsg-${_guidValue}'
var nsgId = (createNetworkSecurityGroup
  ? resourceId('Microsoft.Network/networkSecurityGroups', newNsgName)
  : networkSecurityGroupId)
var vmAvailabilitySetResourceId = {
  id: resourceId('Microsoft.Compute/availabilitySets/', availabilitySetName)
}

var vmIdentityType = (aadJoin
  ? ((!empty(userAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned')
  : ((!empty(userAssignedIdentity)) ? 'UserAssigned' : 'None'))

var vmIdentityTypeProperty = {
  type: vmIdentityType
}
var vmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/',userAssignedIdentity)}': {}
  }
}

var vmIdentity = ((!empty(userAssignedIdentity))
  ? union(vmIdentityTypeProperty, vmUserAssignedIdentityProperty)
  : vmIdentityTypeProperty)
var powerShellScriptName = (empty(customConfigurationScriptUrl) ? null : last(split(customConfigurationScriptUrl, '/')))
var securityProfile = {
  uefiSettings: {
    secureBootEnabled: secureBoot
    vTpmEnabled: vTPM
  }
  securityType: securityType
}
var managedDiskSecurityProfile = {
  securityEncryptionType: managedDiskSecurityEncryptionType
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: '${vmName}-nic'
  location: location
  extendedLocation: (empty(extendedLocation) ? null : extendedLocation)
  tags: networkInterfaceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    networkSecurityGroup: (empty(networkSecurityGroupId) ? null : json('{"id": "${nsgId}"}'))
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  extendedLocation: (empty(extendedLocation) ? null : extendedLocation)
  tags: virtualMachineTags
  identity: vmIdentity
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: ((availabilityOption == 'AvailabilitySet') ? vmAvailabilitySetResourceId : null)
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    securityProfile: (((securityType == 'TrustedLaunch') || (securityType == 'ConfidentialVM')) ? securityProfile : null)
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: (empty(vmGalleryImageVersion) ? 'latest' : vmGalleryImageVersion)
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: ((rdshVmDiskSizeGB == 0) ? null : rdshVmDiskSizeGB)
        managedDisk: {
          storageAccountType: storageAccountType
          securityProfile: ((securityType == 'ConfidentialVM') ? managedDiskSecurityProfile : null)
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmName}-nic')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: bootDiagnostics
    }
    additionalCapabilities: {
      hibernationEnabled: rdshHibernate
    }
    licenseType: 'Windows_Client'
  }
}

resource guestAttestation 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = if (integrityMonitoring) {
  name: 'GuestAttestation'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
        AscSettings: {
          ascReportingEndpoint: ''
          ascReportingFrequency: ''
        }
        useCustomToken: 'false'
        disableAlerts: 'false'
      }
    }
  }
}

resource AVDAgent 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = if (avdAgent)  {
  name: 'Microsoft.PowerShell.DSC'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolName
        registrationInfoTokenCredential: {
          UserName: 'PLACEHOLDER_DO_NOT_USE'
          Password: 'PrivateSettingsRef:${reference(hostpoolid, '2021-07-12', 'Full').properties.registrationInfo.token}'
        }
        aadJoin: aadJoin
        UseAgentDownloadEndpoint: true
        aadJoinPreview: (contains(systemData, 'aadJoinPreview') && systemData.aadJoinPreview)
        mdmId: (intune ? '0000000a-0000-0000-c000-000000000000' : '')
        sessionHostConfigurationLastUpdateTime: SessionHostConfigurationVersion
      }
    }
    protectedSettings: {
      Items: {
        RegistrationInfoToken: hostpoolToken
      }
    }
  }
  dependsOn: [
    guestAttestation
  ]
}

resource aadLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = if (aadJoin && (contains(
    systemData,
    'aadJoinPreview')
  ? (!systemData.aadJoinPreview)
  : true)) {
  name: 'AADLoginForWindows'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: (intune
      ? {
          mdmId: '0000000a-0000-0000-c000-000000000000'
        }
      : null)
  }
  dependsOn: [
    AVDAgent
  ]
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (!empty(customConfigurationScriptUrl)) {
  name: 'Microsoft.Compute.CustomScriptExtension'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        customConfigurationScriptUrl
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${powerShellScriptName}'
    }
  }
  dependsOn: [
    AVDAgent
    aadLoginForWindows
  ]
}
