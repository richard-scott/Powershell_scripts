<#
.SYNOPSIS
Sandbox for testing Powershell commands.
#>
. C:\Dev\Powershell\Installer\Config.ps1
. C:\Dev\Powershell\Installer\Utilities.ps1
Clear
write-host "==============================="  
write-host "Playing in the  powershell sandbox!"  
write-host "==============================="

$cx_folder = "$script:CX_WORKSPACE\CustusX3"
Get-ChildItem $cx_folder -Filter "build*" -Name

#Test-QtBuilt $script:CX_QT_BUILD_X64

#$testType = @'
#// Sample for the Environment.Version property 
#using System;
#
#public class Test{
#    public Test()
#    {
#        Console.WriteLine();
#        Console.WriteLine("Version: {0}", Environment.Version.ToString());
#    }
#}
#'@
#Add-Type -TypeDefinition $testType -Language CSharp
#$sample = New-Object Test

#Get-WmiObject -query "select Name from Win32_SerialPort"

#Mount-NetworkDrive "\\medtek.sintef.no\MedTekDisk"
#Mount-NetworkDrive "\\medtek.sintef.no\MedTekDisk" -username "medtek" -password "mi8kir"
#[System.IO.DriveInfo]::GetDrives()
#Get-PSDrive

#$username=""
#if(-not $username)
#{Write-Host Test}

#[Environment]::GetEnvironmentVariable("path", "user")
#[Environment]::GetEnvironmentVariable("path", "machine")

#[Environment]::CommandLine

#$log = New-Object Log("C:\Users\jbake\Desktop\log.txt")
#$log.addSUCCESS("Test1")
#$log.addERROR("Test2")
#$log.addWARNING("Test3")
#$log.addINFO("Test4")
#$log.addDEBUG("Test5")
#$log.print()
#Remove-Variable -Force $log -Scope Global


#$test = "TEST"
#Add-Logging 'SUCCESS' ("Downloaded "+$test+"!")

#$color = "Red"
#Write-Host "Test" -ForegroundColor $color

#$time = Get-Date
#Get-ElapsedTime "Test"

#$scriptpath = $MyInvocation.MyCommand.Path
#$dir = Split-Path $scriptpath
#Write-host "My directory is $dir"


#$application="powershell"
#
#$al = $application.Length
#$appfolderpath = $application.SubString(0, $al - ($application.Split("\")[$application.Split("\").Count - 1].Length))
#
#$objshell = New-Object -ComObject "Shell.Application"
#$objfolder = $objshell.Namespace($appfolderpath)
#$appname = $objfolder.ParseName($application.SubString($al - ($application.Split("\")[$application.Split("\").Count - 1].Length)))
#$verbs = $appname.verbs()
#$verbs

#$tool_actions = @("all", "install")
#(($tool_actions -contains "all") -or ($tool_actions -contains "install"))

#$32bit_compiler=$true
#$target_archs=@("x86", "x64")
#$build32bit = ($32bit_compiler -and ($target_archs -contains "x86"))
#$build32bit

#$here = @"
#Linje1`n
#"@
#$here += @"
#Linje2
#"@
#$here

#Function Test{
#    param(
#        ## The title of the new tab.
#        [Parameter(Mandatory=$true, Position=0)]
#        [ValidateSet('X', 'Y', 'Z')]
#        [string[]]$test
#    )
#}
#Test @('X','Y','A')


#param (
#    [Parameter(Mandatory=$false, position=0, HelpMessage="Select installation type. (normal, full, partial)")]
#    [ValidateSet('normal', 'full', 'partial')]
#    [string]$false, 
#    [Parameter(Mandatory=$false, position=1, HelpMessage="Select installation mode. (-all, download, install, environment")]
#   [ValidateSet('all', 'download', 'install', 'environment')]
#    [string]$mode,
#    [Parameter(Mandatory=$false, HelpMessage="Select tool(s). (7zip, cppunit, jom, git, svn, cmake, python, eclipse, qt, boost, mvs2010expressCpp)")]
#    [string[]]$tools
#)

#Clear
#Write-host "Tools: "$tools

#switch ($type)
#{
#    "normal" { Write-Host "Normal"}
#    "full" {Write-Host "Full"}
#    "partial" {Write-Host "Partial"}
#    default {Write-Host "Default"}
#}

#if((($mode -eq "all") -or ($mode -eq "download")))
#{Write-Host "Downloading"}
#if((($mode -eq "all") -or ($mode -eq "install")))
#{Write-Host "Installing"}
#if((($mode -eq "all") -or ($mode -eq "environment")))
#{Write-Host "Setting up environment"}


#$employee_list = @() # Dynamic array definition 
#write-host "-------------------------------"  
#write-host "Checking array information"  
#write-host "-------------------------------" 
#$employee_list.gettype() # Check array information 

#$Host.UI.RawUI.BackgroundColor="magenta"
#$Host.UI.RawUI.ForegroundColor="white"
#$Host.UI.RawUI.BufferSize
#exit 99

#$cxVarsFile = "akjsdbasx64"
# if("$cxVarsFile" -like '*x64*' ) {
#   Write-Host '***** Setup CustusX (x64) Development environment *****' -ForegroundColor Green;
#   if(!(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64'))
#    {Write-Host 'You do NOT have a 64 bit compiler installed!' -ForegroundColor Red;}
# }elseif("$cxVarsFile" -like '*x86*' ) {
#   Write-Host '***** Setup CustusX (x86) Development environment *****' -ForegroundColor Green;
# };

#powershell -NoExit -Command "&{
# if('$cxVarsFile' -like '*x64*' ) {
#   Write-Host '***** Setup CustusX (x64) Development environment *****' -ForegroundColor Green;
#   if(!(Test-Path 'C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\bin\amd64'))
#    {Write-Host 'You do NOT have a 64 bit compiler installed!' -ForegroundColor Red;}
# }elseif('$cxVarsFile' -like '*x86*' ) {
#   Write-Host '***** Setup CustusX (x86) Development environment *****' -ForegroundColor Green;
# };
#}"