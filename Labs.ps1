$DEBUG = $True

# LAB A
function Get-ComputerInfo
{
<#
.SYNOPSIS
Retrieves key system version, model and system information from one to ten computers.
.DESCRIPTION
Get-ComputerInfo uses Windows Management Instrumentation (WMI) to retrieve information from one or more computers. Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses - up to a maximum of 10.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to '.\errors.txt'.
.EXAMPLE
Get-Content ComputerNames.txt | Get-ComputerInfo
.EXAMPLE
Get-ComputerInfo -ComputerName Server1, Server2
#>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True,
                   HelpMessage="Computer's name or IP address"
                   )]
        [ValidateCount(1,10)]
        [Alias('HostName')]
        [string[]]
        $computerName='localhost'
    ,
        [string]
        $ErrorLog='.\LabA_errors.txt'
    ,
        [switch]
        $LogErrors
    )

    Begin
    {
        Write-Verbose "Starting Get-ComputerInfo..."
        if($LogErrors)
        {
            Write-Verbose "Logging errors in '$ErrorLog'"
        }
        else
        {
            Write-Verbose "Not logging errors"
        }
    }

    Process
    {
        Write-Verbose "Processing request..."

        foreach($computer in $computerName)
        {
            Write-Verbose "Getting data from '$computer'..."
            
            try
            {
                $compFound = $True
                Write-Verbose "Win32_OperatingSystem"
                $os = Get-WmiObject -Class Win32_OperatingSystem `
                                    -ComputerName $computer `
                                    -ErrorAction Stop `
                                    -ErrorVariable err
            }
            catch
            {
                $compFound = $False
                if($LogErrors)
                {
                    $computer | Out-File $ErrorLog -Append
                }
                
                Write-Error $err[0].message
            }

            if($compFound)
            {
                Write-Verbose "Win32_ComputerSystem"
                $comp = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer
                Write-Verbose "Win32_BIOS"
                $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $computer
            
                $props = @{'ComputerName'=$computer;
                           'Workgroup'=$comp.Workgroup;
                           'AdminPassword'=$comp.AdminPasswordStatus;
                           'Model'=$comp.Model;
                           'Manufacturer'=$comp.Manufacturer;
                           'BIOSSerial'=$bios.SerialNumber;
                           'OSVersion'=$os.Version;
                           'SPVersion'=$os.ServicePackMajorVersion;
                           }
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }

    End
    {
        Write-Verbose "Ending Get-ComputerInfo"
    }
}

# LAB B

Function Get-DiskInfo
{
<#
.SYNOPSIS
Retrieves hard disk storage information from one to ten computers.
.DESCRIPTION
Get-DiskInfo uses Windows Management Instrumentation (WMI) to retrieve storage information from one or more computers. Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses - up to a maximum of 10.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to '.\errors.txt'.
.EXAMPLE
Get-Content ComputerNames.txt | Get-DiskInfo
.EXAMPLE
Get-DiskInfo -ComputerName Server1, Server2
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True,
                   HelpMessage="Computer's name or IP address"
                   )]
        [ValidateCount(0,10)]
        [string[]]
        $computername='localhost'
    ,
        [string]
        $ErrorLog='.\LabB_errors.txt'
    ,
        [switch]
        $LogErrors
    )

    Begin
    {
        Write-Verbose "Starting Get-DiskInfo..."
        if($LogErrors)
        {
            Write-Verbose "Logging errors in '$ErrorLog'"
        }
        else
        {
            Write-Verbose "Not logging errors"
        }
    }
    
    Process
    {
        Write-Verbose "Processing request..."
        foreach($computer in $computername)
        {
            Write-Verbose "Getting disk info for '$computer'"
            
            try
            {
                $compFound = $True
                $disks=Get-WmiObject -Class Win32_Logicaldisk `
                                     -Filter "Drivetype=3" `
                                     -ComputerName $computer `
                                     -EA Stop `
                                     -EV err
            }
            catch
            {
                $compFound = $False
                if($LogErrors)
                {
                    $computer | Out-File $ErrorLog -Append
                }
                Write-Error $err[0].message
            }
            if($compFound)
            {
                foreach ($disk in $disks)
                {
                    Write-Verbose " Processing disk '$disk'"
                    $perFree=($disk.FreeSpace/$disk.Size)*100;

                    $props = @{'ComputerName'=$computer;
                               'Drive'=$disk.DeviceID;
                               'FreeSpace'=$perFree;
                               'Size'=$disk.Size;
                               }
                    $obj = New-Object -TypeName PSObject -Property $props
                    Write-Output $obj
                }
            }
        }
    }

    End
    {
        Write-Verbose "Ending Get-DiskInfo"
    }
}

# LAB C

function Get-ProcessInfo
{
<#
.SYNOPSIS
Retrieves process information from one to ten computers.
.DESCRIPTION
Get-ProcessInfo uses Windows Management Instrumentation (WMI) to retrieve storage information from one or more computers. Specify computers by name or by IP address.
.PARAMETER ComputerName
One or more computer names or IP addresses - up to a maximum of 10.
.PARAMETER StartMode
Valid options: 'Boot', 'System', 'Auto', 'Manual' & 'Disabled'
Used to only search for a processes with a specific start mode - defaults to 'All'.
.PARAMETER LogErrors
Specify this switch to create a text log file of computers that could not be queried.
.PARAMETER ErrorLog
When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to '.\errors.txt'.
.EXAMPLE
Get-Content ComputerNames.txt | Get-ProcessInfo
.EXAMPLE
Get-ProcessInfo -ComputerName Server1, Server2
#>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$True,
                   HelpMessage="Computer's name or IP address"
                   )]
        [ValidateCount(0,10)]
        [Alias('HostName')]
        [string[]]
        $ComputerName="localhost"
    ,
        [ValidateSet('Boot', 'System', 'Auto', 'Manual','Disabled')]
        [string]
        $StartMode = '*'
    ,
        [ValidateSet('Stopped', 'Start Pending', 'Stop Pending', 'Running', 'Continue Pending', 'Pause Pending', 'Paused', 'Unknown')]
        [string]
        $State = '*'
    ,
        [string]
        $ErrorLog = '.\LabC_errors.txt'
    ,
        [switch]
        $LogErrors
    ,
        [switch]
        $PeakPageFileUsage
    ,
        [switch]
        $ThreadCount
    )

    Begin
    {
        Write-Verbose "Beginning Get-ProcessInfo..."
        if($LogErrors)
        {
            Write-Verbose "-Logging errors in '$ErrorLog'"
        }
        else
        {
            Write-Verbose "-Not logging errors"
        }
    }

    Process
    {
        Write-Verbose "Processing request..."
        Write-Verbose " StartMode   : $startmode"
        Write-Verbose " State       : $state"
        Write-Verbose " Show Threads: $ThreadCount"
        Write-Verbose " Show PPF Use: $PeakPageFileUsage"

        foreach($computer in $ComputerName)
        {
            Write-Verbose "Getting services from '$computer'"

            try
            {
                $compFound = $True
                $services = Get-WmiObject Win32_Service -ComputerName $computer -EA Stop -EV err | 
                Where-Object {$_.StartMode -like $startMode -and $_.State -like $state}
            }
            catch
            {
                $compFound = $False
                if($LogErrors)
                {
                    $computer | Out-File $ErrorLog -Append
                }
                Write-Error $err[0].message
            }

            if($compFound)
            {
                foreach($service in $services)
                {
                    $process = Get-WMIObject -class Win32_Process -computername $computer -Filter "ProcessID='$($service.processid)'" 

                    $props = @{'ComputerName'=$computer;
                               'ProcessName'=$process.Name;
                               'VMSize'=$process.VirtualSize;
                               }

                    if($PeakPageFileUsage)
                    {
                        $props.Add("PeakPageFile", $process.PeakPageFileUsage)
                    }
                    if($ThreadCount)
                    {
                        $props.Add("ThreadCount", $process.ThreadCount)
                    }

                    $obj = New-Object -TypeName PSObject -Property $props
                    Write-Output $obj
                }
            }
        }
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
When used with -LogErrors, specifies the file path and name to which failed computer names will be written. Defaults to '.\Get-SystemInfo_errors.txt'.
.EXAMPLE
Get-Content ComputerNames.txt | Get-SystemInfo
.EXAMPLE
Get-SystemInfo -ComputerName Server1, Server2
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   HelpMessage="Computer's name or IP address"
                   )]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1,10)]
        [string[]]
        $ComputerName
    ,
        [string]
        $ErrorLog='.\Get-SystemInfo_errors.txt'
    ,
        [switch]
        $LogErrors
    )

    PROCESS
    {
        foreach ($computer in $computerName)
        {
            Write-Verbose "Getting data from '$computer'"

            try
            {
                $compFound = $True
                $os = Get-WmiObject -class Win32_OperatingSystem `
                                    -computerName $computer `
                                    -EA Stop `
                                    -EV err
            }
            catch
            {
                $compFound = $False
                if($LogErrors)
                {
                    $computer | Out-File $ErrorLog -Append
                }
                Write-Error $err[0].message
            }

            if($compFound)
            {
                $cs = Get-WmiObject -class Win32_ComputerSystem `
                                    -computerName $computer
                $props = @{'ComputerName'=$computer;
                           'LastBootTime'=($os.ConvertToDateTime($os.LastBootupTime));
                           'OSVersion'=$os.version;
                           'Manufacturer'=$cs.manufacturer;
                           'Model'=$cs.model
                           }
                $obj = New-Object -TypeName PSObject -Property $props
                Write-Output $obj
            }
        }
    }
}

if($DEBUG)
{
    #Get-ComputerInfo 'localhost',NOTONLINE -Verbose -LogErrors
    #Get-DiskInfo 'localhost',NOTONLINE -Verbose -LogErrors
    #Get-ProcessInfo localhost,NOTONLINE -StartMode Auto -State Running -ThreadCount -PeakPageFileUsage -Verbose -LogErrors | Format-Table -AutoSize
    Get-SystemInfo -ComputerName 'localhost','NotOnline' -Verbose -LogErrors
}