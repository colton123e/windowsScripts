<#
Created by: Colton Estes on 31 Mar 21
Description:
    My first PS script, designed to simply convert the ESD file found on a Windows ISO to a WIM file for import into an SCCM-like application.
    Note: This script does require elevated rights to run.
Usage: 
Required: ./ESD_to_WIM.ps1 -PathToISO "X:\directory\to\ISOFile.iso"
Optionally, you can specify the destination and file name for the .wim file to be exported to.
If this is not specified, it will default to the working directory with the name "install.wim"
    Optional: ./ESD_to_WIM.ps1 -PathToISO "X:\directory\to\ISOFile.iso" -DestinationPath "Y:\some\other\dir\wimfile.wim"
#>
param( [Parameter(Mandatory=$true)] $PathToISO,
       [Parameter(Mandatory=$false)] $DestinationPath
       )
    #If a destination path is not provided, the default is the working directory with "install.wim" as the file name
if (-not($DestinationPath)) {
        [string]$workingdir = (Get-Location | Select-Object Path).Path
        [string]$DestinationPath = $workingdir + "\install.wim"
    }
#1. Get list of current drive letters
$predrives = Get-PSDrive -PSProvider FileSystem | Select-Object Name

#2. Mount the ISO file provided via user input at command line
Mount-DiskImage -ImagePath $PathToISO

#3. Get new list of drives
$postdrives = Get-PSDrive -PSProvider FileSystem | Select-Object Name

Write-Output "`r`n"
#4. Get the difference between two drive lists to find the mounted drive
$differentdrive = (Compare-Object -ReferenceObject $postdrives -DifferenceObject $predrives -Property Name -PassThru).Name

#5. Get WindowsImage from the new drive letter
$esdpath = $differentdrive + ":\sources\install.esd"

Get-WindowsImage -ImagePath $esdpath | Out-Default

#6. Get user's input on which version they would like (image index)
$imageindex = Read-Host -Prompt 'Input the number of the ImageIndex you would like'
if ($imageindex) {
    Write-Host "Selected ImageIndex [$imageindex] for export"
} else {
    Write-Warning -Message "No imageindex selected."
}
#7. Export the WIM file
Export-WindowsImage -SourceImagePath $esdpath -SourceIndex $imageindex -DestinationImagePath $DestinationPath -CheckIntegrity

#8. Unmount the ISO image
Dismount-DiskImage -ImagePath $PathToISO