<#
Copyright (c) 2018-2021 VMware, Inc.  All rights reserved

The BSD-2 license (the "License") set forth below applies to all parts of the Desired State Configuration Resources for VMware project.  You may not use this file except in compliance with the License.

BSD-2 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>

class DscConfigurationBlockExtent {
    [string] $StartLine

    [string] $Text

    [string] $EndLine
}

class DscConfigurationBlock {
    [string] $Name

    [System.Collections.Hashtable] $ConfigurationData

    [DscConfigurationBlockExtent] $Extent
}

class DscConfigurationFileParser {
    <#
    .DESCRIPTION

    Parses the PowerShell script file containing the DSC Configurations by performing the following steps:

    1. Extracts each DSC Configuration defined in the file and converts it into a DscConfigurationBlock object, which contains
    the following information: the name of the DSC Configuration, the configurationData defined as hashtable which is needed
    if the DSC Configuration retrieves data from it. Also the object contains the text information for the DSC Configuration:
    the start and end line of the DSC Configuration in the file and also the DSC Configuration as text. This whole information
    is later passed to the DscConfigurationCompiler which compiles it and produces the VmwDscConfiguration object.

    2. Invokes all non DSC Configuration lines in the provided file and this ways makes them available in the current scope. This way
    for example if there is configurationData defined, the hashtable will be available in memory for the DscConfigurationCompiler to
    produce the VmwDscConfiguration object.
    #>
    [DscConfigurationBlock[]] ParseDscConfigurationFile([string] $dscConfigurationFilePath) {
        $dscConfigurationFileContent = Get-Content -Path $dscConfigurationFilePath
        $dscConfigurationFileContentRaw = Get-Content -Path $dscConfigurationFilePath -Raw

        $tokens = [System.Management.Automation.PSParser]::Tokenize($dscConfigurationFileContentRaw, [ref]$null)
        $dscConfigurations = $this.GetAllDscConfigurations($tokens)

        $scriptContent = [System.Text.StringBuilder]::new()
        $dscConfigurationsContent = [System.Text.StringBuilder]::new()

        $j = 0
        for ($i = 0; $i -lt $dscConfigurationFileContent.Length; $i++) {
            if ($i -lt ($dscConfigurations[$j].Extent.StartLine - 1) -or $i -gt $dscConfigurations[$j].Extent.EndLine) {
                $scriptContent.AppendLine($dscConfigurationFileContent[$i]) | Out-Null
            }
            else {
                $dscConfigurationsContent.AppendLine($dscConfigurationFileContent[$i]) | Out-Null
            }

            if ($i + 1 -gt $dscConfigurations[$j].Extent.EndLine - 1) {
                $dscConfigurationsContentAsString = $dscConfigurationsContent.ToString()

                # Only the content of the DSC Configuration is needed so we trim the Configuration keyword and the name of the DSC Configuration.
                $dscConfigurationsContentAsString = $dscConfigurationsContentAsString.TrimStart('Configuration').TrimStart()
                $dscConfigurationsContentAsString = $dscConfigurationsContentAsString.TrimStart($dscConfigurations[$j].Name).TrimStart()

                $dscConfigurationsContentAsString = $dscConfigurationsContentAsString.TrimEnd()

                # After the text of the DSC Configuration is retrieved, we clear the content, so that we can start
                # with an empty string for the next DSC Configuration in the file.
                $dscConfigurations[$j].Extent.Text = $dscConfigurationsContentAsString
                if ($j -lt ($dscConfigurations.Length - 1)) {
                    $dscConfigurationsContent = [System.Text.StringBuilder]::new()
                    $j++
                }
            }
        }

        # The ScriptBlock is invoked for all non DSC Configurations lines.
        $scriptContentAsString = $scriptContent.ToString()
        $scriptBlock = [ScriptBlock]::Create($scriptContentAsString)
        $scriptBlock.Invoke()

        <#
            In the file there should be only one configurationData hashtable for all defined DSC Configurations. If the user wants to use different
            configurationData hashtables, the DSC Configurations should be defined in separate files as there is no way to know which hashtable is for
            which DSC Configuration. So the assumption is that there should be only one hashtable defined with the AllNodes key in the file.
        #>
        $configurationData = Get-Variable |
            Where-Object -FilterScript { $null -ne $_.Value -and $_.Value.GetType() -eq [System.Collections.Hashtable] -and $_.Value.ContainsKey('AllNodes') } |
            Select-Object -First 1
        if ($null -ne $configurationData -and $scriptContentAsString -Match $configurationData.Name) {
            foreach ($dscConfiguration in $dscConfigurations) {
                $dscConfiguration.ConfigurationData = $configurationData.Value
            }
        }

        return $dscConfigurations
    }

    <#
    .DESCRIPTION

    Extracts each DSC Configuration defined in the file and converts it into a DscConfigurationBlock object. The content of the file is passed
    as an array of PSTokens from which each DSC Configuration info is extracted.
    #>
    hidden [DscConfigurationBlock[]] GetAllDscConfigurations([System.Collections.ObjectModel.Collection[System.Management.Automation.PSToken]] $tokens) {
        $dscConfigurations = @()

        for ($i = 0; $i -lt $tokens.Count; $i++) {
            $token = $tokens[$i]

            if ($token.Type -eq 'Keyword' -and $token.Content -eq 'Configuration') {
                $dscConfiguration = [DscConfigurationBlock]::new()
                $dscConfiguration.Extent = [DscConfigurationBlockExtent]::new()
                $dscConfiguration.Extent.StartLine = $token.StartLine

                $j = $i + 1
                $dscConfigurationBlockReached = $false
                $endOfDscConfigurationReached = $false
                $bracketsCounter = 0

                while ($j -lt $tokens.Count -and !$endOfDscConfigurationReached) {
                    $dscConfigurationToken = $tokens[$j]

                    # The name of the DSC Configuration is in the token of type CommandArgument.
                    if ($null -eq $dscConfiguration.Name -and $dscConfigurationToken.Type -eq 'CommandArgument') {
                        $dscConfiguration.Name = $dscConfigurationToken.Content
                    }

                    if ($dscConfigurationToken.Type -eq 'GroupStart' -and $dscConfigurationToken.Content -eq '{') {
                        if (!$dscConfigurationBlockReached) {
                            $dscConfigurationBlockReached = $true
                        }

                        $bracketsCounter++
                    }

                    if ($dscConfigurationToken.Type -eq 'GroupEnd' -and $dscConfigurationToken.Content -eq '}') {
                        $bracketsCounter--
                    }

                    # bracketsCounter equal to zero indicates that the closing bracket of the current DSC Configuration was reached.
                    if ($dscConfigurationBlockReached -and $bracketsCounter -eq 0) {
                        $dscConfiguration.Extent.EndLine = $dscConfigurationToken.EndLine
                        $endOfDscConfigurationReached = $true
                    }

                    <#
                        The first index should be updated at each step, so after the nested loop finishes and
                        the DSC Configuration block is populated with the text of the DSC Configuration,
                        the first loop continues from the end of the current DSC Configuration.
                    #>
                    $j++
                    $i = $j
                }

                $dscConfigurations += $dscConfiguration
            }
        }

        return $dscConfigurations
    }
}
