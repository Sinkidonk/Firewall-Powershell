## This script will go and help you set up static IPv4 and IPv6 addresses
## Default gatewys, DNS Servers, and set up firewall rules
## This script will also be able to enable dhcp
## I will make use of Comments, Variables, if else and or switch statements and Loops
## All functions will go at the very beginning of the script
## I will make use of a variable array for firewall rules
## Will be making use of a fixed array for DNS Server addresses.
## I will make a command line interface to guide users around on making use of the script
## If I have time and can figure out how I will make the setting up firewall rules use a csv file for it input
## 
## Author: Alex Parys
## Created: 4/7/2019

## https://www.pdq.com/blog/using-powershell-to-set-static-and-dhcp-ip-ad


## Note to Self working with PowerShell is annoying
## Output of some commands change base on whenever you are running it from a script, or from the powershell command line
## Making it extremely hard to test very small subsection of script code, where the debugging tool should not be required


function startupMenu {
    Clear-Host
    Write-Output "Hello There"
    Write-Output "Welcome to our networking setup script"
    Write-Output "In This script you can view your Network config info"
    Write-Output "Change networking setting"
    Write-Output "View or add stuff to the firewall"
    Write-Output "And Enable DHCP"
    Read-Host -Prompt "Press Enter to continue"

}

function selectedMenu {
    Clear-Host
    Write-Output "1) Set a Static IP Address"
    Write-Output "2) Set the DNS Servers Addresses"
    Write-Output "3) Enable DHCP"
    Write-Output "4) Set up firewall rules"
    Write-Output "Type Exit to quit the program"
    $global:selcted = Read-Host "Please select a number"
}



function firewallSetup {
    Clear-Host
    ##This part would benefits highly from being able to use cvs file as it input
    ## New-NetFirewallRule -DisplayName "Block Outbound Port 80" -Direction Outbound -LocalPort 80 -Protocol TCP -Action Block
    Write-Output "This can only allow or block by port numbers"
    ## For some reason when I try to make it take a user input for the path it don't want to take
    ## So I had to hard-code the file path in the script
    Write-Output "If not already done put the firewall.csv file in the root of the c drive"
    Read-Host -Prompt "Press Enter to continue"
    #$csvFile = Read-Host
    
    $csvFile = Import-Csv "C:\firewall.csv"
    foreach ($value in $csvFile)
    {
        New-NetFirewallRule `
            -name $value.name `
            -DisplayName $value.name `
            -LocalPort $value.portNum `
            -Protocol $value.protocol `
            -Action $value.action
    }

     Read-Host -Prompt "Press Enter to continue"
}



function netAda {
    Get-NetAdapter | ? {$_.Status -eq "up"}
    
}

function enableDHCP($adp) {

    ## Note to self Functions that depend on more then one input variable will use an array to keep all the values in

    
    ## https://etechgoodness.wordpress.com/2013/01/18/removing-an-adapter-gateway-using-powershell/
    netsh interface ip set address “$adp” dhcp
}

## I learned in my ClearIPInfo function that output of some commands change base on whenever you are running them from a script
## or dirctly from the command line, making it extramly hard to pull the info I need to put into the parameter
## also some of the output I needed to pulled just didn't exist once I ran them from the script.
## Also finding best way to clear out ip info is to just enable dhcp
## powershell way to enable dhcp don't clear out the default gateway value
## without all values being cleared out I keep getting an error msg
## The old school command line way to enable dhcp is the best way to
## clear out the ip address info

function ClearIPInfo($interType) {
    ## [0] Adapter, [1] IPType
    $gateway = Get-NetIPConfiguration -InterfaceAlias $Adapter
    if($interType[1] = "ipv4") {
        $ip = (Get-NetAdapter -Name "$interType[0]" | Get-NetIPAddress).IPv4Address
        $gateway = $gateway.IPv4DefaultGateway | Select-Object NextHop
        $gateway = [string]$gateway -replace ".*=" -replace "}"
    } elseif($interType[1] = "ipv6") {
        $ip = (Get-NetAdapter -Name "$interType[0]" | Get-NetIPAddress).IPv6Address
        $gateway = $gateway.IPv6DefaultGateway | Select-Object NextHop
        $gateway = [string]$gateway -replace ".*=" -replace "}"
    }
    $mask = (Get-NetAdapter -Name "Ethernet" | Get-NetIPAddress -AddressFamily $interType[1]).PrefixLength
    

    Remove-NetIPAddress `
        -InterfaceAlias $interType[0] `
        -AddressFamily $interType[1] `
        -IPAddress $ip `
        -PrefixLength $mask `
        -DefaultGateway $gateway
    
}

function StaticIP {
    Clear-Host
    #Get interfaces that are up to display to the user what interfaces are up and can be config
    netAda
    $Adapter = Read-Host "Please Type in the name of the interface to modify"
    #$IPType = Read-Host "IPv4, or IPv6"
    $IPType = "IPv4"
    $IP = Read-Host "Enter in the IP Address"
    $Mask = Read-Host "Enter in the Prefix Length"
    $Gateway = Read-Host "Enter in the Default gateway"
    #Set-NetIPInterface -InterfaceAlias $Adapter -Dhcp Enabled
    #Set-NetIPInterface -InterfaceAlias $Adapter -Dhcp Disabled
    
    #ClearIPInfo($Adapter, $IPType)
    enableDHCP($Adapter)

    #if ($IPType -match "ipv4") {
    #    ClearIPInfo($IPType)
    #} Elseif ($IPType -match "Ipv6") {
    #    Remove-NetIPAddress -InterfaceAlias $Adapter -AddressFamily $IPType
    #}
    
    $NNetIp = New-NetIPAddress `
        -InterfaceAlias $Adapter `
        -AddressFamily $ipType `
        -IPAddress $IP `
        -PrefixLength $Mask `
        -DefaultGateway $Gateway

        Write-Output "Your interface now have the values of"
        Write-Output "IP Address: $IP"
        Write-Output "Prefix: $Mask"
        Write-Output "Gateway: $Gateway"
        Read-Host -Prompt "Press Enter to continue"

    
    
}

function DnsSetup {
    Clear-Host
    netAda
    $Adapter = Read-Host "Please Type in the name of the interface to setup DNS Servers with"
    $IPType = "IPv4"
    $DnsServer = @(0) * 2
    
    for ($i=0; $i -lt $DnsServer.Length; $i++) {
        $DnsServer[$i]=Read-Host "Enter Dns Server Address"
    }
    Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses ($DnsServer[0],$DnsServer[1])

    $dnsclient = Get-DnsClientServerAddress -InterfaceAlias $Adapter -AddressFamily $IPType
    Write-Output "Your DNS Servers Addresses are now"
    $dnsclient.ServerAddresses
    Read-Host -Prompt "Press Enter to continue"


}



function DHCPMenu {
    Clear-Host
    netAda
    
    $Adapter = Read-Host "Please Type in the name of the interface to modify"
    #$IPType = Read-Host "Please type in IPv4 or IPv6 for the interface you want enable DHCP for"
    #$IPType = "ipv4"
    enableDHCP($Adapter)
    Write-Output "DHCP is now enabled"
    Read-Host -Prompt "Press Enter to continue"


}

function quitMsg {
    Clear-Host
    Write-Output "Good Bye!"
    exit
}


## Due to some issues ipv6 functionally of this script will be disabled
## I am having more issues with ipv6 then I can deal with and I can't even correctly test it anyway
## Due to my internet service providers not allowing ipv6 yet


startupMenu


while($true)
{
    selectedMenu
    Switch ($selcted) {
        1 {
            StaticIP
        }
        2 {
            DnsSetup
        }
        3 {
            DHCPMenu
        }
        4 {
            firewallSetup
        }
        Exit { 
            quitMsg
        }
    }
}

## New-NetIPAddress -InterfaceAlias "Wi-Fi" -IPAddress "192.168.1.58" -PrefixLength 24 -DefaultGateway 192.168.1.1
## Need to find a way to make it not error out on me while trying to set it up


