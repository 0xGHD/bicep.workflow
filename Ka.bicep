param adminUsername string
@minLength(12)
@secure()


param adminPassword string
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
param publicIpName string = 'myPublicIP'
param publicIPAllocationMethod string = 'Dynamic'
param publicIpSku string = 'Basic'
param OSVersion string = '2022-datacenter-azure-edition'
param vmSize string = 'Standard_D2s_v5'
param location string = resourceGroup().location
param vmName string = 'simple-vm'
param securityType string = 'TrustedLaunch'
var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = 'myVMNic'
var nic2Name = 'myVMNic2'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet1'
var subnet2Name = 'Subnet2'
var subnetPrefix = '10.0.0.0/24'
var subnet2Prefix = '10.0.1.0/24'
var virtualNetworkName = 'MyVNET'
var networkSecurityGroupName = 'default-NSG'



resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
        type: 'string'
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
        type: 'string'
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource vm2publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: vm2publicIPAddressName
  location: locationvm2
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vm2dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}

resource nic2 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nic2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vm2publicIPAddress.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnet2Name)
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}





var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}



resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}






param vm2 string = 'VM2'
param Adm2 string
param vm2authenticationType string = 'password'
@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param vm2adminPasswordOrKey string
param vm2dnsLabelPrefix string = toLower('${vm2}-${uniqueString(resourceGroup().id)}')
param ubuntuOSVersion string = 'Ubuntu-2004'
param locationvm2 string = resourceGroup().location
param vm2Size string = 'Standard_D2s_v3'
param vm2networkSecurityGroupName string = 'SecGroupNet'
var vm2imageReference = {
  'Ubuntu-1804': {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '18_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2004': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-focal'
    sku: '20_04-lts-gen2'
    version: 'latest'
  }
  'Ubuntu-2204': {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
}
var vm2publicIPAddressName = '${vm2}PublicIP'
var vm2osDiskType = 'Standard_LRS'

var vm2linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${Adm2}/.ssh/authorized_keys'
        keyData: vm2adminPasswordOrKey
      }
    ]
  }
}







resource vm2networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: vm2networkSecurityGroupName
  location: locationvm2
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}








resource virtualmachine2 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vm2
  location: locationvm2
  properties: {
    hardwareProfile: {
      vmSize: vm2Size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vm2osDiskType
        }
      }
      imageReference: vm2imageReference[ubuntuOSVersion]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
        }
      ]
    }
    osProfile: {
      computerName: vm2
      adminUsername: Adm2
      adminPassword: vm2adminPasswordOrKey
      linuxConfiguration: ((vm2authenticationType == 'password') ? null : vm2linuxConfiguration)
    }
  }
}

