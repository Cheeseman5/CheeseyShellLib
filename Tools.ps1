$DEBUG = $true

function Get-OSInfo
{
    Param(
        [string]$computerName = "$localhost"
    )
    Get-CimInstance -ClassName Win32_OperatingSystem `
                    -ComputerName $computerName
}

function Get-ProcessByState
{
    param(
        [ValidateSet('Auto', 'Manual','Disabled')]
        [string]
        $startMode = '*'
    ,
        [ValidateSet('Running', 'Stopped')]
        [string]
        $state = '*'
    )

    Get-WmiObject Win32_Service | 
    Where-Object {$_.StartMode -like $startMode -and $_.State -like $state}
}

Function Get-DiskInfo
{
    Param (
        [string]$computername='localhost'
    ,
        [int]$MinimumFreePercent=10
    )
    
    $disks=Get-WmiObject -Class Win32_Logicaldisk -Filter "Drivetype=3"
    
    foreach ($disk in $disks)
    {
        $perFree=($disk.FreeSpace/$disk.Size)*100;
        
        if ($perFree -ge $MinimumFreePercent) 
        {
            $OK=$True
        }
        else
        {
            $OK=$False
        }
        
        $disk|Select DeviceID,VolumeName,Size,FreeSpace,@{Name="OK";Expression={$OK}}
    }
}

function Get-SystemInfo
{
<#
.SYNOPSIS
Retrieves key system version and model information from one to ten computers.
.DESCRIPTION
Get-SystemInfo uses Windows Management Instrumentation (WMI) to retrieve information from one or more computers. Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses - up to a maximum of 10.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to '.\retry.txt'.
.EXAMPLE
Get-Content ComputerNames.txt | Get-SystemInfo
.EXAMPLE
Get-SystemInfo -ComputerName Server1, Server2
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   HelpMessage="Computer name or IP address"
                   )]
        [ValidateCount(1,10)]
        [Alias('HostName')]
        [string[]]
        $ComputerName
    ,
        [string]
        $ErrorLog = '.\retry.txt'
    ,
        [switch]
        $LogErrors
    )

    Begin
    {
        Write-Verbose "Error log will be '$errorlog'"
    }

    Process
    {
        Write-Verbose "Beginning PROCESS block..."
        foreach($computer in $ComputerName)
        {
            Write-Verbose "Querying '$computer'"
            
            try
            {
                $CompFound = $True
                $os = Get-WmiObject -Class Win32_OperatingSystem `
                                    -ComputerName $computer `
                                    -ErrorAction Stop
            }
            catch
            {
                $CompFound = $False
                Write-Warning "'$computer' failed"
                
                if($LogErrors)
                {
                    $computer | Out-File $ErrorLog -Append
                    Write-Warning "Logged to '$ErrorLog'"
                }
            }

            if($CompFound)
            {
                $comp = Get-WmiObject -Class Win32_ComputerSystem `
                                      -ComputerName $computer
                $bios = Get-WmiObject -Class Win32_BIOS `
                                      -ComputerName $computer
            
                Write-Verbose "WMI queries complete"

                $props = @{'ComputerName'=$computer;
                           'OSVersion'=$os.Version;
                           'SPVersion'=$os.ServicepackMajorVersion;
                           'BIOSSerial'=$bios.SerialNumber;
                           'Manufacturer'=$comp.Manufacturer;
                           'Model'=$comp.Model}
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
}

# for testing/debugging only
if($DEBUG)
{
    #Get-OSInfo
    
    #Get-ProcessByState -startMode auto -state Stopped | Select-Object Name, StartMode, State | Sort-Object Name
    
    #Get-DiskInfo | Select-Object DeviceID,Size,@{Name="Used"; Expression={"{0,5:p}" -f (($_.Size-$_.FreeSpace)/$_.Size)}}
    
    #Help Get-SystemInfo -Full

    if($true)
    {

        #Write-Host "----[ PARAM TEST ]----"
        Get-SystemInfo -Host localhost, NOTONLINE -ErrorLog .\x.txt -LogErrors

        <#Write-Host "----[ PIPELINE TEST ]----"
        'localhost','localhost' | Get-SystemInfo -Verbose#>

        <#Write-Host "----[ COUNT TEST ]----"
        #1..15 | ForEach-Object -Process {Write-Output 'localhost'} | Get-SystemInfo
        Get-SystemInfo -Host 'localhost','localhost','localhost','localhost','localhost','localhost','localhost',
            'localhost','localhost','localhost','localhost','localhost'#>
    }
}