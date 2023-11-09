<#
.SYNOPSIS
    A simple function to block all traffic inbound and outobund for an NSG.

.DESCRIPTION
    Updates an Azure NSG disallowing all traffic, useful in IR scenarios. Function can be further extended to allow 
    
.NOTES
    Has an 'if' condition to allow whitelisting certain port or a a CIDR, in case of IR tooling or if needed to upload artifacts. Only triggers if 
.EXAMPLE 
#>

function Block-VMNetworkAccess {
    [CmdLetBinding()]
    param ( 
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [string]
        $NSGName,
        [Parameter(Mandatory = $false)]
        [string]
        $AllowPort,
        [Parameter(Mandatory = $false)]
        [string]
        $AllowPrefix
    )


    $ResourceGroupName
    $NSGName

    # Get the NSG resource
    $NSGObject = Get-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName


    $InboundIRSecurityRuleConfigParams = @{
        Name                     = "BlockAllInboundIR"
        Description              = "Deny all inbound access to isolate workload"
        Access                   = "Deny"
        Protocol                 = "*"
        Direction                = "Inbound"
        Priority                 = "112"
        SourceAddressPrefix      = "*"
        SourcePortRange          = "*"
        DestinationPortRange     = "*"
        DestinationAddressPrefix = "*"
        NetworkSecurityGroup     = $NSGObject
    }
    $OutboundIRSecurityRuleConfigParams = @{
        Name                     = "BlockAllOutboundIR"
        Description              = "Deny all outbound access to isolate workload"
        Access                   = "Deny"
        Protocol                 = "*"
        Direction                = "Outbound"
        Priority                 = "113"
        SourceAddressPrefix      = "*"
        SourcePortRange          = "*"
        DestinationPortRange     = "*"
        DestinationAddressPrefix = "*"
        NetworkSecurityGroup     = $NSGObject
    }

    Add-AzNetworkSecurityRuleConfig @InboundIRSecurityRuleConfigParams
    Add-AzNetworkSecurityRuleConfig @OutboundIRSecurityRuleConfigParams 



    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSGObject

    if ($AllowPrefix -eq $true -and $AllowPort -eq $true) {
        $AllowPort = '445'
        $AllowPrefix = '10.0.0.1/32'

        $InboundIRSecurityRuleExemptConfigParams = @{
            Name                     = "AllowInboundIR"
            Description              = "Allow specific inbound access for IR"
            Access                   = "Allow"
            Protocol                 = "*"
            Direction                = "Inbound"
            Priority                 = "110"
            SourceAddressPrefix      = "*"
            SourcePortRange          = "*"
            DestinationPortRange     = $AllowPort
            DestinationAddressPrefix = $AllowPrefix
            NetworkSecurityGroup     = $NSGObject
        }
        $OutboundIRSecurityRuleExemptConfigParams = @{
            Name                     = "AllowOutBoundIR"
            Description              = "Allow specific outbound access for IR"
            Access                   = "Allow"
            Protocol                 = "*"
            Direction                = "Outbound"
            Priority                 = "111"
            SourceAddressPrefix      = "*"
            SourcePortRange          = "*"
            DestinationPortRange     = $AllowPort
            DestinationAddressPrefix = $AllowPrefix
            NetworkSecurityGroup     = $NSGObject
        }


        Add-AzNetworkSecurityRuleConfig @InboundIRSecurityRuleExemptConfigParams
        Add-AzNetworkSecurityRuleConfig @OutboundIRSecurityRuleExemptConfigParams 
        Set-AzNetworkSecurityGroup -NetworkSecurityGroup $NSGObject
    }
}
