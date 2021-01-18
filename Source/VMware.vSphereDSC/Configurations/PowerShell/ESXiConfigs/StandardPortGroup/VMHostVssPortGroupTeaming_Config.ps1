<#
Copyright (c) 2018-2021 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Server,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $User,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Password,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name
)

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (ConvertTo-SecureString -String $Password -AsPlainText -Force)

$script:configurationData = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            PSDscAllowPlainTextPassword = $true
            Server = $Server
            Credential = $Credential
            Name = $Name
        }
    )
}

Configuration VMHostVssPortGroupTeaming_Config {
    Import-DscResource -ModuleName VMware.vSphereDSC

    Node $AllNodes.NodeName {
        VMHostVss VMHostStandardSwitch {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            Name = $AllNodes.Name
            VssName = 'MyVirtualSwitch'
            Ensure = 'Present'
            Mtu = 1500
        }

        VMHostVssBridge VMHostVssBridge {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            Name = $AllNodes.Name
            VssName = 'MyVirtualSwitch'
            Ensure = 'Present'
            BeaconInterval = 1
            LinkDiscoveryProtocolOperation = 'Listen'
            LinkDiscoveryProtocolProtocol = 'CDP'
            NicDevice = @('vmnic2', 'vmnic3')
            DependsOn = "[VMHostVss]VMHostStandardSwitch"
        }

        VMHostVssTeaming VMHostVssTeaming {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            Name = $AllNodes.Name
            VssName = 'MyVirtualSwitch'
            Ensure = 'Present'
            CheckBeacon = $true
            ActiveNic = @('vmnic2', 'vmnic3')
            StandbyNic = @()
            NotifySwitches = $false
            Policy = 'Loadbalance_ip'
            RollingOrder = $true
            DependsOn = "[VMHostVssBridge]VMHostVssBridge"
        }

        VMHostVssPortGroup VMHostVssPortGroup {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            VMHostName = $AllNodes.Name
            Name = 'MyVirtualPortGroup'
            VssName = 'MyVirtualSwitch'
            Ensure = 'Present'
            VLanId = 0
            DependsOn = "[VMHostVssTeaming]VMHostVssTeaming"
        }

        VMHostVssPortGroupTeaming VMHostVssPortGroupTeaming {
            Server = $AllNodes.Server
            Credential = $AllNodes.Credential
            VMHostName = $AllNodes.Name
            Name = 'MyVirtualPortGroup'
            Ensure = 'Present'
            FailbackEnabled = $false
            LoadBalancingPolicy = 'LoadBalanceIP'
            ActiveNic = @('vmnic2', 'vmnic3')
            StandbyNic = @()
            UnusedNic = @()
            NetworkFailoverDetectionPolicy = 'LinkStatus'
            NotifySwitches = $false
            InheritFailback = $false
            InheritFailoverOrder = $false
            InheritLoadBalancingPolicy = $false
            InheritNetworkFailoverDetectionPolicy = $false
            InheritNotifySwitches = $false
            DependsOn = "[VMHostVssPortGroup]VMHostVssPortGroup"
        }
    }
}

VMHostVssPortGroupTeaming_Config -ConfigurationData $script:configurationData
