param location string

param tags object

param hostPoolName string

param description string = 'Azure Virtual Desktop Lab Environment'

param hostPoolType string = 'Pooled'

param customRdpProperty string = '''drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;
redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1'''

param maxSessionLimit int = 3

param loadBalancerType string = 'DepthFirst'

param preferredAppGroupType string = 'RailApplications'

param validationEnvironment bool = true

param baseTime string = utcNow('u')
var add1Days = dateTimeAdd(baseTime, 'P1D')

param enabledForDeployment bool = true

param enabledForDiskEncryption bool = false

param enabledForTemplateDeployment bool = true

param tenantId string = subscription().tenantId

param objectId string

param keysPermissions array = [
  'list'
]

param secretsPermissions array = [
  'list'
]

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

param secretName string = 'hostpoolToken'

resource hostpool 'Microsoft.DesktopVirtualization/hostPools@2022-04-01-preview' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    description: description
    hostPoolType: hostPoolType
    customRdpProperty: customRdpProperty
    maxSessionLimit: maxSessionLimit
    loadBalancerType: loadBalancerType
    registrationInfo: {
      expirationTime: add1Days
      registrationTokenOperation: 'Update'
    }
    validationEnvironment: validationEnvironment
    preferredAppGroupType: preferredAppGroupType
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: 'kv-${hostPoolName}'
 location: location
 properties: {
  enabledForDeployment: enabledForDeployment
  enabledForDiskEncryption: enabledForDiskEncryption
  enabledForTemplateDeployment: enabledForTemplateDeployment
  tenantId: tenantId
  enableSoftDelete: true
  softDeleteRetentionInDays: 90
  accessPolicies: [
    {
      objectId: objectId
      tenantId: tenantId
      permissions: {
        keys: keysPermissions
        secrets: secretsPermissions
      }
    }
  ]
  sku: {
    name: skuName
    family: 'A'
  }
  networkAcls: {
    defaultAction: 'Allow'
    bypass: 'AzureServices'
  }
}
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
parent: keyVault
name: secretName
properties: {
  value: reference(hostpool.id).registrationInfo.token
}
}

output hostpoolId string = hostpool.id
output hostpoolName string = hostpool.name
output registrationInfoToken string = reference(hostpool.id).registrationInfo.token
