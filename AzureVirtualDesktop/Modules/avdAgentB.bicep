param location string = 'westus3'

param tags object = {}

param sessionHostName string = 'vm-avd-prd-001a'

param HostPoolName string = 'hp-avd-prd-wus3'

param SessionHostConfigurationVersion string = ''

param hostpoolToken string = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjdDRjJCQTUzNjY3QjA4RTQzRjA0MDkyODNDMTk0NzhGNDc4OEYxMDYiLCJ0eXAiOiJKV1QifQ.eyJSZWdpc3RyYXRpb25JZCI6IjUwMjk4ZDk1LTM5MzQtNDdlYy1iNWUwLTEwZjY3YjNlZDkwNiIsIkJyb2tlclVyaSI6Imh0dHBzOi8vcmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1VyaSI6Imh0dHBzOi8vcmRkaWFnbm9zdGljcy1nLXVzLXIwLnd2ZC5taWNyb3NvZnQuY29tLyIsIkVuZHBvaW50UG9vbElkIjoiZWMzODBlMTEtODg2ZS00NWNkLThhMTMtOTVkN2Q2MjA4ZjdjIiwiR2xvYmFsQnJva2VyVXJpIjoiaHR0cHM6Ly9yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJHZW9ncmFwaHkiOiJVUyIsIkdsb2JhbEJyb2tlclJlc291cmNlSWRVcmkiOiJodHRwczovL2VjMzgwZTExLTg4NmUtNDVjZC04YTEzLTk1ZDdkNjIwOGY3Yy5yZGJyb2tlci53dmQubWljcm9zb2Z0LmNvbS8iLCJCcm9rZXJSZXNvdXJjZUlkVXJpIjoiaHR0cHM6Ly9lYzM4MGUxMS04ODZlLTQ1Y2QtOGExMy05NWQ3ZDYyMDhmN2MucmRicm9rZXItZy11cy1yMC53dmQubWljcm9zb2Z0LmNvbS8iLCJEaWFnbm9zdGljc1Jlc291cmNlSWRVcmkiOiJodHRwczovL2VjMzgwZTExLTg4NmUtNDVjZC04YTEzLTk1ZDdkNjIwOGY3Yy5yZGRpYWdub3N0aWNzLWctdXMtcjAud3ZkLm1pY3Jvc29mdC5jb20vIiwiQUFEVGVuYW50SWQiOiI2YmZiOGVlMi0zOTE0LTQzZjItOGZlZC1iYzRhODdkNmYyMjQiLCJuYmYiOjE3MjY2MTE5MTgsImV4cCI6MTcyNjY5ODMxNSwiaXNzIjoiUkRJbmZyYVRva2VuTWFuYWdlciIsImF1ZCI6IlJEbWkifQ.C7qi82H5n4_pSibfn2s4u4t478I5kglZYXQuP8pRYUuPJQya6ouaGaCUcbqhLfSTAW1MjtETkYvJnzZq-Qavr3YloHHXBqSm29SlTUyY5fMHp63x5vgUyF5_ZVUOIpI-LRifASXXWjpEQmwrj457EClKGWqJ_X1IApnB5BG8cP8E9qML5BDj4YQfTsLPWSIDFkRRFVJPm13SUq-6HF2cwVSRkX4ZrZtefussBxBKm9vn9WFf3mwlKbUWgIDn1juIO6moMRgy9mZY1hwiuZIcADTIdug69xZ-yfNIpPjvIKjD_Jvg3V0WphgG_VN9iW35yaO3xGHbOWJd4F13qcmKfg'

param aadJoin bool = true

@description('Specifies whether integrity monitoring will be added to the virtual machine.')
param integrityMonitoring bool = false

@description('System data is used for internal purposes, such as support preview features.')
param systemData object = {}

param intune bool = false

var artifactsLocation = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02705.330.zip'

resource existingVirtualMachine 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: sessionHostName
}

resource guestAttestation 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = if (integrityMonitoring) {
  name: 'GuestAttestation'
  parent: existingVirtualMachine
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

resource AVDAgent 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'Microsoft.PowerShell.DSC'
  parent: existingVirtualMachine
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
        hostPoolName: HostPoolName
        RegistrationInfoToken: hostpoolToken
        aadJoin: aadJoin
        UseAgentDownloadEndpoint: true
        aadJoinPreview: (contains(systemData, 'aadJoinPreview') && systemData.aadJoinPreview)
        mdmId: (intune ? '0000000a-0000-0000-c000-000000000000' : '')
        sessionHostConfigurationLastUpdateTime: SessionHostConfigurationVersion
      }
    }
    }
    dependsOn: [
      guestAttestation
    ]
  }
