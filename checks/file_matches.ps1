#
# This script will search all local drives for files with names
# that match the specified file pattern.
#

#
# Usage:
#
# .\file_matches.ps1 -Pattern *foobar* -OutputPath $env:TEMP
#

#
# The script will output a file that contains matches (if any)
# for every drive with the name [machinename]_[drive letter]_drive_mathes.csv.
#

param (
    [Parameter(Mandatory=$true)]
    [String]
    $OutputPath,
    [Parameter(Mandatory=$true)]
    [string]$Pattern
)

function qnd_find_files() {

    [System.Collections.ArrayList]$drives = (wmic logicaldisk where drivetype=3 get name).Where({ $_ -ne "" })
    $drives.RemoveAt(0)

    foreach ($drive in $drives) {
        $letter = $drive -replace '[: ]'
        $ResultsFile = $OutputPath + "\" + $env:ComputerName + "_" + $letter  + "_drive_matches.csv"
        ls $drive -recurse $Pattern | Select-Object -Property FullName | Export-Csv -Path $ResultsFile
    }
}

qnd_find_files
