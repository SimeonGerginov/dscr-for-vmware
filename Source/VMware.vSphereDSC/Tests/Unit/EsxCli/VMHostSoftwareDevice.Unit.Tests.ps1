<#
Copyright (c) 2018-2021 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

Using module '..\..\..\VMware.vSphereDSC.psm1'

$script:moduleName = 'VMware.vSphereDSC'

InModuleScope -ModuleName $script:moduleName {
    try {
        $unitTestsFolder = Join-Path (Join-Path (Get-Module VMware.vSphereDSC -ListAvailable).ModuleBase 'Tests') 'Unit'
        $modulePath = $env:PSModulePath
        $resourceName = 'VMHostSoftwareDevice'

        . "$unitTestsFolder\TestHelpers\TestUtils.ps1"

        # Calls the function to Import the mocked VMware.VimAutomation.Core module before all tests.
        Invoke-TestSetup

        . "$unitTestsFolder\TestHelpers\Mocks\MockData.ps1"
        . "$unitTestsFolder\TestHelpers\Mocks\VMHostSoftwareDeviceMocks.ps1"

        Describe 'VMHostSoftwareDevice\Set' -Tag 'Set' {
            BeforeAll {
                # Arrange
                $resourceProperties = New-MocksInSetForVMHostSoftwareDevice
                $resource = New-Object -TypeName $resourceName -Property $resourceProperties
            }

            It 'Should invoke all defined mocks with the correct parameters' {
                # Act
                $resource.Set()

                # Assert
                Assert-VerifiableMock
            }
        }

        Describe 'VMHostSoftwareDevice\Test' -Tag 'Test' {
            BeforeAll {
                # Arrange
                New-MocksForVMHostSoftwareDevice
            }

            Context 'When the VMHost Software device does not exist and Ensure is Present' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceDoesNotExistAndEnsureIsPresent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Test()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should return $false when the VMHost Software device does not exist and Ensure is Present' {
                    # Act
                    $result = $resource.Test()

                    # Assert
                    $result | Should -Be $false
                }
            }

            Context 'When the VMHost Software device exists and Ensure is Present' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceExistsAndEnsureIsPresent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Test()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should return $true when the VMHost Software device exists and Ensure is Present' {
                    # Act
                    $result = $resource.Test()

                    # Assert
                    $result | Should -Be $true
                }
            }

            Context 'When the VMHost Software device does not exist and Ensure is Absent' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceDoesNotExistAndEnsureIsAbsent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Test()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should return $true when the VMHost Software device does not exist and Ensure is Absent' {
                    # Act
                    $result = $resource.Test()

                    # Assert
                    $result | Should -Be $true
                }
            }

            Context 'When the VMHost Software device exists and Ensure is Absent' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceExistsAndEnsureIsAbsent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Test()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should return $false when the VMHost Software device exists and Ensure is Absent' {
                    # Act
                    $result = $resource.Test()

                    # Assert
                    $result | Should -Be $false
                }
            }
        }

        Describe 'VMHostSoftwareDevice\Get' -Tag 'Get' {
            BeforeAll {
                # Arrange
                New-MocksForVMHostSoftwareDevice
            }

            Context 'When the VMHost Software device does not exist and Ensure is Present' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceDoesNotExistAndEnsureIsPresent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Get()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should retrieve and return the correct values from the class properties' {
                    # Act
                    $result = $resource.Get()

                    # Assert
                    $result.Server | Should -Be $script:viServer.Name
                    $result.Name | Should -Be $script:vmHost.Name
                    $result.DeviceIdentifier | Should -Be $resourceProperties.DeviceIdentifier
                    $result.InstanceAddress | Should -Be $resourceProperties.InstanceAddress
                    $result.Ensure | Should -Be 'Absent'
                }
            }

            Context 'When the VMHost Software device exists and Ensure is Present' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceExistsAndEnsureIsPresent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Get()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should retrieve and return the correct values from the server' {
                    # Act
                    $result = $resource.Get()

                    # Assert
                    $result.Server | Should -Be $script:viServer.Name
                    $result.Name | Should -Be $script:vmHost.Name
                    $result.DeviceIdentifier | Should -Be $script:constants.SoftwareDeviceId
                    $result.InstanceAddress | Should -Be $script:constants.SoftwareDeviceInstanceAddress
                    $result.Ensure | Should -Be 'Present'
                }
            }

            Context 'When the VMHost Software device does not exist and Ensure is Absent' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceDoesNotExistAndEnsureIsAbsent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Get()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should retrieve and return the correct values from the class properties' {
                    # Act
                    $result = $resource.Get()

                    # Assert
                    $result.Server | Should -Be $script:viServer.Name
                    $result.Name | Should -Be $script:vmHost.Name
                    $result.DeviceIdentifier | Should -Be $resourceProperties.DeviceIdentifier
                    $result.InstanceAddress | Should -Be $resourceProperties.InstanceAddress
                    $result.Ensure | Should -Be 'Absent'
                }
            }

            Context 'When the VMHost Software device exists and Ensure is Absent' {
                BeforeAll {
                    # Arrange
                    $resourceProperties = New-MocksWhenTheVMHostSoftwareDeviceExistsAndEnsureIsAbsent
                    $resource = New-Object -TypeName $resourceName -Property $resourceProperties
                }

                It 'Should invoke all defined mocks with the correct parameters' {
                    # Act
                    $resource.Get()

                    # Assert
                    Assert-VerifiableMock
                }

                It 'Should retrieve and return the correct values from the server' {
                    # Act
                    $result = $resource.Get()

                    # Assert
                    $result.Server | Should -Be $script:viServer.Name
                    $result.Name | Should -Be $script:vmHost.Name
                    $result.DeviceIdentifier | Should -Be $script:constants.SoftwareDeviceId
                    $result.InstanceAddress | Should -Be $script:constants.SoftwareDeviceInstanceAddress
                    $result.Ensure | Should -Be 'Present'
                }
            }
        }
    }
    finally {
        # Calls the function to Remove the mocked VMware.VimAutomation.Core module after all tests.
        Invoke-TestCleanup -ModulePath $modulePath
    }
}
