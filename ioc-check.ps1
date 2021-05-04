#
# Author: Michael Gupton
# Original creation date: 2021-5-3
#

#
# This script checks for some common/generic Windows IOCs.
#
# This includes admin accounts and scheduled tasks created by a
# threat actor.
#
#
# The script will list the admin accounts and sceduled tasks
# and output the results to separate CSV files.
#

#
# Example Usage:
#
# .\ioc-check.ps1 -OutputPath \\myserver\myshare
#

#
# Option -ExcludeMicrosoft will not include scheduled tasks that have
# Microsoft as the author.
#

#
# This script will produce a file named $ComputerName_local_admins.csv
# and $ComputerName_sched_tasks.csv at the path specified in -OutputPath.
#

#
# Specify the path where the output should be written to.
#
param (
    [Parameter(Mandatory=$true)]
    [String]
    $OutputPath,
    [Parameter(Mandatory=$false)]
    [Switch]$ExcludeMicrosoft
)

function get_local_admins() {
    $file_name = $OutputPath + "\" + $env:ComputerName + "_local_admins.csv"
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $osInfo.ProductType
#
# Handle a domain controller differently than a non-domain controller
#
    if ($osInfo.ProductType -eq 1 -or $osInfo.ProductType -eq 3) {
        # Get-LocalGroupMember -Group "Administrators" | Select-Object -Property Name | Export-Csv -Path $file_name
#
# Having to workaround this issue, https://github.com/PowerShell/PowerShell/issues/2996
#
        $outarray = @()

        foreach ($group in Get-LocalGroup -Name Administrators ) {
            $group = [ADSI]"WinNT://$env:COMPUTERNAME/$group"
            $group_members = @($group.Invoke('Members') | % {([adsi]$_).path})
        }

        foreach ($member in $group_members)
        {
            $outarray += New-Object PsObject -property @{
            'Name' = $member
            }
        } 

        $outarray | Export-Csv -Path $file_name        
    }
    elseif ($osInfo.ProductType -eq 2) {
        Get-ADGroupMember -Identity Administrators | Select-Object -Property Name | Export-Csv -Path $file_name
    }
}

function get_sched_tasks() {
    $file_name = $OutputPath + "\" + $env:ComputerName + "_sched_tasks.csv"

    if ($ExcludeMicrosoft -eq $true) {
        Get-ScheduledTask | where Author -notlike "*microsoft*" | Select-Object -Property TaskName, Author | Export-Csv -Path $file_name
    }
    else {
        Get-ScheduledTask | Select-Object -Property TaskName, Author | Export-Csv -Path $file_name
    }
}

get_sched_tasks
get_local_admins
