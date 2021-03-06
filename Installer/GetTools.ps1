<#
.SYNOPSIS
Script that prepares a Windows machine for software development.

.DESCRIPTION
Downloads, installs and sets up environment for:
-Microsoft Visual Studio Express
-7-zip
-CppUnit
-jom
-git
-svn
-CMake
-Python
-Perl
-Eclipse
-Qt
-Boost

.INPUTS
None. You cannot pipe to this script.

.OUTPUTS
None. This script does not generate any output.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 21.05.2012

Microsoft Visual C++ Studio 2010 Express (Free) have some
limitations: 
- No resource editor.
- No built-in MFC support.
- No built-in ATL support.
- No profiling support.
- No built-in x64 compiler (you can download one from the windows SDK).
- No support for OpenMP.
- No support for add-ins or IDE macros.
- Ability to attach the debugger to an already-running process is possible by enabling Tools -> Settings -> Expert settings (starting with 2010).
- No option for crash dump generation (Debug->Save Dump As).
(http://en.wikipedia.org/wiki/Microsoft_Visual_Studio_Express#Visual_C.2B.2B_Express)

#>

# Import other scripts
############################
$psScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
Push-Location $psScriptRoot
. .\Utilities.ps1
. .\Config.ps1
Pop-Location

# Classes
#############################################################################

$toolType = @'
public class Tool{
    public Tool(
        string name, 
        string downloadUrl, 
        string saveAs, 
        string packageType, 
        string installedBinFolder, 
        string extractFolder, 
        string executableName,
        string helpText
        )
    {
        mName = name;
        mDownloadUrl = downloadUrl;
        mSaveAs = saveAs;
        mPackageType = packageType;
        mInstalledBinFolder = installedBinFolder;
        mExtractFolder = extractFolder;
        mExecutableName = executableName;
        mHelpText = helpText;
    }
    
    public string get_name(){ return mName;}
    public string get_downloadUrl(){ return mDownloadUrl;}
    public string get_saveAs(){ return mSaveAs;}
    public string get_packageType(){ return mPackageType;}
    public string get_installedBinFolder(){ return mInstalledBinFolder;}
    public string get_extractFolder(){ return mExtractFolder;}
    public string get_executableName(){ return mExecutableName;}
    public string get_helpText(){ return mHelpText;}
    
    private string mName; //name of the tool
    private string mDownloadUrl; //the url to the downloadable file
    private string mSaveAs; //what the downloaded file should be saved as
    private string mPackageType; //the download file type
    private string mInstalledBinFolder; //where the executable can be found after tool is installed
    private string mExtractFolder; //if package type is extractable archive we need a extraction folder
    private string mExecutableName; //name of the executable
    private string mHelpText; //explaining why the tool is needed
}
'@

<#
.SYNOPSIS
Checks if a tool exists in the current session.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Tool-Exists $git
Checks if the tool exists in the current session.
#>
Function Tool-Exists{
    param(
    ## The tool we want to check if exists
    $tool
    )
    $exists = $false
    
    if(($tool.get_name() -eq "cppunit") -or ($tool.get_name() -eq "boost")){
        if(Test-Path $tool.get_installedBinFolder())
            {$exists = $true}
    }elseif($tool.get_executableName() -and (Command-Exists $tool.get_executableName()))
        {$exists = $true}
    elseif($tool.get_name() -eq "MSVC2010Express"){$exists=Test-MSVCInstalled}
    
    if($exists -eq $true)
        {Add-Logging 'INFO' ($tool.get_name()+" already exists")}
        
    return $exists
}

#Function Download-Tool{
#    param(
#    ## The tool we want to download.
#    $tool
#    )
#
#    $success = $false  
#   
#    $success = Get-DownloadFile $tool
#    
#    if($success)
#        {Add-Logging 'SUCCESS' ("Downloaded "+$tool.get_name()+"!")}
#    else
#        {Add-Logging 'ERROR' ("Could not download "+$tool.get_name()+", you will have to do it manually!")}
#        
#    return $success
#}

<#
.SYNOPSIS
Tries to download a tools installer file.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Download-Tool $git
Tries to download gits installer file.
#>
Function Download-Tool{
    param(
    ## The tool we want to download the installer file for.
    $tool
    )
    $success = $false
    try{
        Add-Logging 'INFO'  ("Downloading "+$tool.get_name())
        $webclient = New-Object Net.WebClient
        $webclient.DownloadFile($tool.get_downloadUrl(), $tool.get_saveAs())
        Add-Logging 'INFO' "Download done."
        $success = $true
    }
    catch
    {
        Add-Logging 'ERROR' ("Exception caught when trying to download "+$tool.get_name()+" from "+$url+" to "+$targetFile+".")
    }
    finally
    {
        if($success)
            {Add-Logging 'SUCCESS' ("Downloaded "+$tool.get_name()+"!")}
        else
            {Add-Logging 'ERROR' ("Could not download "+$tool.get_name()+", you will have to do it manually!")}
        return $success
    }
}

<#
.SYNOPSIS
Tries to install a tool.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Install-Tool $git
Tries to install git.
#>
Function Install-Tool{
    param(
    ## The tool we want to install.
    $tool
    )
    $success = $false 

    $success = Run-Installer $tool
    
    if($success){
        Add-Logging 'SUCCESS' ("Installed "+$tool.get_name()+"!")
        if($tool.get_name() -like 'console2'){
        $toolname = $tool.get_name()
            $icon = $script:CX_ENVIRONMENT_FOLDER+"\"+$toolname+".ico"
            Export-Icon $tool.get_executableName() $icon
            Add-Shortcut ("$HOME\Desktop\$toolname.lnk") ("`""+$tool.get_installedBinFolder()+"\"+$tool.get_executableName()+".exe`"") "" "$icon"
        }
    }
    else
        {Add-Logging 'ERROR' ("Could not install "+$tool.get_name()+", you will have to do it manually!")}
        
    return $success
}

<#
.SYNOPSIS
Runs the tools installer.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Run-Installer $git
Runs the downloaded git installer.
#>
Function Run-Installer{
    param(
    ## The tool we want to run the installer for.
    $tool
    )

    Add-Logging 'INFO' ("Installing "+$tool.get_name())
    
    $success = $false
    $packageType = $tool.get_packageType()
    if($packageType -eq "NSIS package"){
        #piping to Out-Null seems to by-pass the UAC
        Start-Process $tool.get_saveAs() -ArgumentList "/S" -NoNewWindow -Wait | Out-Null
        $success = $true    
    }
    elseif($packageType -eq "Inno Setup package"){
        #piping to Out-Null seems to by-pass the UAC
        Start-Process $tool.get_saveAs() -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-" -NoNewWindow -Wait | Out-Null
        $success = $true
    }
    elseif($packageType -eq "MSI"){
        $installer = $tool.get_saveAs()
        Start-Process msiexec -ArgumentList "/i $installer /quiet /passive" -NoNewWindow -Wait
        $success = $true
    }
    elseif($packageType -eq "ZIP"){
        $shell_app = new-object -com shell.application
        $zip_file = $shell_app.namespace($tool.get_saveAs())

        $destinationFolder = $tool.get_extractFolder()
        if(!(Test-Path $destinationFolder))
            {mkdir $destinationFolder}
        $destination = $shell_app.namespace($destinationFolder)
        $destination.Copyhere($zip_file.items(),0x14) #0x4 hides dialogbox, 0x10 overwrites existing files, 0x14 combines both
        
        if($tool.get_name() -eq "qt"){
            Add-Logging 'DEBUG' "Found qt, going to copy!"
            $qt_extracted = (Get-Item $tool.get_installedBinFolder()).Parent.FullName
            Add-Logging 'DEBUG' ('$qt_extracted '+$qt_extracted)
            Copy-Item $qt_extracted -Destination $script:CX_QT_BUILD_X86 -Recurse
            Add-Logging 'INFO' "Copied Qt to $script:CX_QT_BUILD_X86"
            Copy-Item $qt_extracted -Destination $script:CX_QT_BUILD_X64 -Recurse
            Add-Logging 'INFO' "Copied Qt to $script:CX_QT_BUILD_X64"
        }
        $success = $true
    }
    elseif($packageType -eq "TarGz"){
        $z ="7z.exe"

        #Destination folder cannot contain spaces for 7z to work with -o
        $destinationFolder = $tool.get_extractFolder()
        if(!(Test-Path $destinationFolder))
            {mkdir $destinationFolder}
        Add-Logging 'DEBUG' ('$destinationFolder '+$destinationFolder)
         
        $targzSource = $tool.get_saveAs()
        Add-Logging 'DEBUG' ('$targzSource '+$targzSource)
        & "$z" x -y $targzSource #| Out-Null
        
        $tarSource = (Get-Item $targzSource).basename
        Add-Logging 'DEBUG' ('$tarSource '+$tarSource)
        & "$z" x -y $tarSource "-o$destinationFolder" #| Out-Null #Need to have double quotes around the -o parameter because of whitespaces in destination folder
   
        Remove-Item $tarSource
        
        $success = $true
    }
    elseif($packageType -eq "EXE"){
        #Made to work with the Microsoft Visual Studio 2010 Express C++ web installer
        Start-Process $tool.get_saveAs() -ArgumentList "/q /norestart" -NoNewWindow -Wait | Out-Null
        # Need to restart?
        #Start-Process $tool.get_saveAs() -ArgumentList "/q" -NoNewWindow -Wait | Out-Null
        $success = $true
    }
    elseif($packageType -eq "UPX Packed executable"){
        #Made to work with Firefox.exe installer
        Start-Process $tool.get_saveAs() -ArgumentList "-ms" -NoNewWindow -Wait | Out-Null
        $success = $true
    }
    else{
        Add-Logging 'ERROR' ("Could not figure out which installer "+$tool.get_name()+" has used, could not install "+$tool.get_name()+".")
    }

    return $success
}

<#
.SYNOPSIS
Adds a tools installed path to the system environment for this session.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Add-ToPathSession "C:\PathToExe\Test.exe"
Will make the Test.exe reachable in the current session.
#>
Function Add-ToPath{
    param(
    ## The tool that we want to make available.
    $tool
    )
    
    Add-Logging 'INFO' ("Adding "+$tool.get_name()+" to system environment.")

    $success = $false 
    
    $path = $tool.get_installedBinFolder()
    Add-ToPathSession($path)
    $success = $true
    
    return $success
}

# Creates a bat file that sets up a CustusX build environment
Function Create-Cx-Environment($saveName, $targetPlatform, $extendedPath){
    $qt_dir = ""
    if($targetPlatform -eq "x86")
        {$qt_dir = $script:CX_QT_QTDIR_X86}
    elseif($targetPlatform -eq "x64")
        {$qt_dir = $script:CX_QT_QTDIR_X64}
    else
        {Add-Logging 'ERROR'  "Error while making environment, could not figure out which architecure."}
    $qt_bin = $qt_dir+"\bin"
    Add-Logging 'DEBUG' ('$qt_bin '+$qt_bin)
    $extendedPath = $qt_bin+";"+$extendedPath
    Add-Logging 'DEBUG' ('$extendedPath '+$extendedPath)
    
    $content = @"
@echo off
rem
rem This file is automatically generated by the Windows installer script for CustusX
rem

echo ====================================================
echo Setting up a CustusX ($targetPlatform) environment...
echo ====================================================
echo.
echo ******* Setting up a tool enabled environment *******
set PATH=%PATH%;$extendedPath
echo -- Added $extendedPath to session PATH
echo.

echo ******* Setting up Qt environment *******
:: Copied from qtvars.bat
set QTDIR=$qt_dir
set QMAKESPEC=$script:CX_QT_QMAKESPEC
echo -- QTDIR set to $qt_dir
echo -- QMAKESPEC set to "$script:CX_QT_QMAKESPEC"
echo.

echo ******* Setting up Microsoft Visual Studio $script:CX_MSVC_VERSION ($targetPlatform) environment *******
call "$script:CX_MSVC_VCVARSALL" $targetPlatform

"@

    $envFileFullName = $saveName

    $stream = New-Object System.IO.StreamWriter($envFileFullName)
    $stream.WriteLine($content)
    $stream.Close()
    
    Add-Logging 'SUCCESS'  "Created environment file $envFileFullName"
    
    return $envFileFullName
}

<#
.SYNOPSIS
Creates a shortcut to a batch file that run a tool within custusx environment

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Create-Batch-Exe 'cmd' "$script:CX_CXVARS_64" "C:\Temp"
Will create a shortcut to the command executable loaded with custusX 64bit environment.
Files are saved in C:\Temp.
#>
Function Create-Batch-Exe{
    param(
    ## The executable that should be loaded in a specific environment
    $toolExecutableName,
    ## The bat file that sets up the environment
    $cxVarsFile,
    ## The folder where the files should be saved
    $saveFolder
    )

    #TODO
    #Will eclipse executed in 64 bit environment build 32 bit builds???
    
    if(!(Test-Path $cxVarsFile))
        {Add-Logging 'WARNING' "Cannot create batch exe because $cxVarsFile cannot be found."}
    
    #variables
    $toolName = $toolExecutableName
    if($toolName -eq "cmake"){
        $toolName = "cmake-gui"
    }
    $cxVarsFileBase = ((Get-Item $cxVarsFile | Select-Object basename )).basename
    $batchName = "$toolName-$cxVarsFileBase"
    $batchEnding = ".bat"
    
    $batchPath = "$saveFolder\$batchName$batchEnding"
    $toolExe = (Get-Command $toolName | Select-Object Name).Name
    $toolFolder = (Get-Item (Get-Command $toolName | Select-Object Definition).Definition).directory.fullname

    $desktopFolder = "$HOME\Desktop\"
    $taskbarFolder = "$HOME\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\Taskbar\"
    $shortcutFolder = $desktopFolder
    
    #write content for normal executables
    $content = @"
@cd $saveFolder
@call $cxVarsFile > nul 2>&1
@cd $toolFolder
@start $toolExe > nul 2>&1
@exit
"@
    #Powershell specifics
    if($toolName -eq "powershell")
    {
        $command = "if('$cxVarsFile' -like '*x64*' ) {Write-Host '***** Setup CustusX 64 bit (x64) Development environment *****' -ForegroundColor Green; if(!(Test-Path `'$script:CX_MSVC_CL_X64`')){Write-Host 'You do NOT have a 64 bit compiler installed!' -ForegroundColor Red;}}elseif('$cxVarsFile' -like '*x86*' ) {Write-Host '***** Setup CustusX 32 bit (x86) Development environment *****' -ForegroundColor Green;};"
        $content = @"
@call $cxVarsFile > nul 2>&1
powershell -NoExit -Command "& {$command}"
"@
        if("$cxVarsFile" -like '*x64*' ){Add-Console2Tab -TabTitle "Powershell CX:x64" -ConsoleShell "$batchPath" -InitalDir "$script:CX_WORKSPACE\CustusX3\" -SaveSettingsToUserDir $true}
        elseif("$cxVarsFile" -like '*x86*' ){Add-Console2Tab -TabTitle "Powershell CX:x86" -ConsoleShell "$batchPath" -InitalDir "$script:CX_WORKSPACE\CustusX3\" -SaveSettingsToUserDir $true}
    }

    $stream = New-Object System.IO.StreamWriter($batchPath)
    $stream.WriteLine($content)
    $stream.Close()
    
    #extract icon
    $icon = $script:CX_ENVIRONMENT_FOLDER+"\"+$toolname+".ico"
    Export-Icon $toolName $icon
    
    #create shortcut on taskbar
    $arch = "x86"
    if("$cxVarsFile" -like '*x64*' ){$arch = "x64"}
    $shortcutPath = "$shortcutFolder"+"\"+$toolName+"_"+$arch+".lnk"
    
    Add-Shortcut $shortcutPath 'cmd.exe' "/C ""$batchPath""" "$icon"
    
    Add-Logging 'SUCCESS' "Created shortcut to $toolExecutableName started in a CustusX environment!"
    
    return $true
}

<#
.SYNOPSIS
Configures the git installation.

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 01.04.2012

.EXAMPLE
Configure-Git 'Developer' 'dev@sintef.no'
Configures the git installation.
#>
Function Configure-Git{
    param(
    ## The name that commits should be signed with
    $name,
    ## The e-mail adressed used by git to associate git commits to a person
    $email
    )
    ## See https://help.github.com/articles/set-up-git
    git config --global user.name $name
    git config --global user.email $email
    git config --global credential.helper 'cache --timeout=86400' # Will only work when you clone an HTTPS repo URL. If you use the SSH repo URL instead, SSH keys are used for authentication.
    
    git config --global color.diff auto
    git config --global color.status auto
    git config --global color.branch auto
    git config --global core.autocrlf input
    git config --global core.filemode false #(ONLY FOR WINDOWS)
    
    Add-Logging 'EMPHASIS' "Configured git, see: git config --list"
}

<#
.SYNOPSIS
Convenience function for checking out, configuring and building CustusX.

WARNING: Depends on Config.ps1

.NOTES
AUTHOR: Janne Beate Bakeng, SINTEF
DATE: 05.09.2012

.EXAMPLE
Get-Tools 'full' 'all'
Get all available tools. Download, install and setup CustusX environment for them.

.EXAMPLE
Get-Tools 'partial' 'all' -tools @('git', 'jom')
Get git and jom. Download, install and setup CustusX environment for them.
#>
Function Get-Tools {

param (
    ## Select installation package, which tools to install
    [Parameter(Mandatory=$true, position=0, HelpMessage="Select installation type. (developer, minimum, full, partial)")]
    [ValidateSet('developer', 'minimum', 'full', 'partial')]
    [string]$type, 
    ## Select which mode to run in, what should be done with the selected tools
    [Parameter(Mandatory=$true, position=1, HelpMessage="Select installation mode. (all, download, install, environment")]
    [ValidateSet('all', 'download', 'install', 'environment')]
    [string[]]$mode,
    ## Manually picking tools, use with $type='partial'
    [Parameter(Mandatory=$false, HelpMessage="Select tool(s). (7-Zip, cppunit, jom, git, svn, cmake, python, perl, eclipse, qt, boost, MSVC2010Express, console2, nsis, firefox, cuda)")]
    [ValidateSet('7-Zip', 'cppunit', 'jom', 'git', 'svn', 'cmake', 'python', 'perl', 'eclipse', 'qt', 'boost', 'MSVC2010Express', 'console2', 'nsis', 'firefox', 'cuda')]
    [string[]]$tools
)

## Add class definition it to the powershell session
Add-Type -TypeDefinition $toolType

#Information 
#--------------
$ToolFolder = $script:CX_TOOL_FOLDER
$CxEnvFolder = $script:CX_ENVIRONMENT_FOLDER

#Available tools
#--------------
## Tool( Name, DownloadURL, SaveAs, PackageType, InstalledBinFolder, ExtractFolder, ExecutableName, HelpText )

# Microsoft Visual C++ Studio Express 2010
$msvc2010Express = New-Object Tool("MSVC2010Express", "http://go.microsoft.com/?linkid=9709949", "$ToolFolder\MVS2010Express_web.exe", "EXE", "$script:CX_PROGRAM_FILES_X86\Microsoft Visual Studio 10.0\VC\bin", "", "nmake", "This free version does not support 64 bit compiling or redistribution.")
# 7-Zip 9.20 (x64)
$7zip = New-Object Tool("7-Zip", "http://downloads.sourceforge.net/sevenzip/7z920-x64.msi", "$ToolFolder\7-Zip-installer.msi", "MSI", "$script:CX_PROGRAM_FILES\7-Zip", "", "7z", "Needed to untar CppUnit.")
# CppUnit 1.12.1
$cppunit = New-Object Tool("cppunit", "http://sourceforge.net/projects/cppunit/files/cppunit/1.12.1/cppunit-1.12.1.tar.gz/download", "$ToolFolder\CppUnit.tar.gz", "TarGz", "$script:CX_EXTERNAL_CODE\cppunit-1.12.1", "$script:CX_EXTERNAL_CODE", "", "Used to write tests in CustusX.")
# jom
$jom = New-Object Tool("jom", "ftp://ftp.qt.nokia.com/jom/jom.zip", "$ToolFolder\jom.zip", "ZIP", "$script:CX_DEFAULT_DRIVE\Program Files\jom", "$script:CX_PROGRAM_FILES\jom", "jom", "Enables support for compiling using more than one core.")
# git 1.7.10 (x86?)
$git = New-Object Tool("git", "http://msysgit.googlecode.com/files/Git-1.7.10-preview20120409.exe", "$ToolFolder\git-installer.exe", "Inno Setup package", "$script:CX_PROGRAM_FILES_X86\Git\cmd", "", "git", "Version control system.")
# Silk SVN 1.7.5 (x64) (NOTE: will add itself to system path!)
$svn = New-Object Tool("svn", "http://www.sliksvn.com/pub/Slik-Subversion-1.7.5-x64.msi", "$ToolFolder\svn-installer.msi", "MSI", "$script:CX_PROGRAM_FILES\SlikSvn\bin", "", "svn", "Version control system.")
# CMake 2.8.10.1 (x86)
$cmake = New-Object Tool("cmake", "http://www.cmake.org/files/v2.8/cmake-2.8.10.1-win32-x86.exe", "$ToolFolder\cmake-installer.exe", "NSIS package", "$script:CX_PROGRAM_FILES_X86\CMake 2.8\bin", "", "cmake", "For generating make files.")
# NSIS 2.46
$nsis = New-Object Tool("nsis", "http://downloads.sourceforge.net/project/nsis/NSIS%202/2.46/nsis-2.46-setup.exe?r=http%3A%2F%2Fnsis.sourceforge.net%2FDownload&ts=1346835031&use_mirror=garr", "$ToolFolder\nsis-installer.exe", "NSIS package", "$script:CX_PROGRAM_FILES_X86\NSIS", "", "NSIS", "NSIS (Nullsoft Scriptable Install System) is a professional open source system to create Windows installers.")
# CUDA 4.2.9 (x64)
#$cuda = New-Object Tool("cuda", "http://developer.download.nvidia.com/compute/cuda/4_2/rel/toolkit/cudatoolkit_4.2.9_win_64.msi", "$ToolFolder\cuda_toolkit.msi", "MSI", "$script:CX_PROGRAM_FILES\NVIDIA GPU Computing Toolkit\CUDA\v4.2\bin", "", "cudafe", "The NVIDIA CUDA Toolkit provides a comprehensive development environment for C and C++ developers building GPU-accelerated applications.")
# CUDA 5.0.35 (x64, win8/win7/winvista)
$cuda = New-Object Tool("cuda", "http://developer.download.nvidia.com/compute/cuda/5_0/rel-update-1/installers/cuda_5.0.35_winvista_win7_win8_general_64-1.msi", "$ToolFolder\cuda_toolkit.msi", "MSI", "$script:CX_PROGRAM_FILES\NVIDIA GPU Computing Toolkit\CUDA\v5.0\bin", "", "cudafe", "The NVIDIA CUDA Toolkit provides a comprehensive development environment for C and C++ developers building GPU-accelerated applications.")
# Python 2.7
$python = New-Object Tool("python", "http://www.python.org/ftp/python/2.7.3/python-2.7.3.msi", "$ToolFolder\python-installer.msi", "MSI", "$script:CX_DEFAULT_DRIVE\Python27", "", "python", "Needed to run cxInstaller.py script that will download, configure and build all needed code for CustusX.")
# Active Perl 5.14.2.1402 (x64)
$perl = New-Object Tool("perl", "http://downloads.activestate.com/ActivePerl/releases/5.14.2.1402/ActivePerl-5.14.2.1402-MSWin32-x64-295342.msi", "$ToolFolder\perl-installer.msi", "MSI", "$script:CX_DEFAULT_DRIVE\Perl64\bin", "", "perl", "Needed for building Qt.")
# Eclipse Indigo (x86_64)
$eclipse = New-Object Tool("eclipse", "http://eclipse.mirror.kangaroot.net/technology/epp/downloads/release/indigo/SR2/eclipse-cpp-indigo-SR2-incubation-win32-x86_64.zip", "$ToolFolder\eclipse.zip", "ZIP", "$script:CX_PROGRAM_FILES\eclipse", "$script:CX_PROGRAM_FILES", "eclipse", "Optional development gui.")
# Qt 4.8.1 vs2010, 32 bit libs only, installer
#$qt = New-Object Tool("qt", "ftp://ftp.qt.nokia.com/qt/source/qt-win-opensource-4.8.1-vs2010.exe", "$ToolFolder\qt.exe", "NSIS package", "$script:CX_DEFAULT_DRIVE\Qt\4.8.1\bin", "", "qmake", "No 64 bit libs, only 32 bit libs.") #Installing Qt this way only gives x86 libs
# Qt, CX_QT_VERSION==4.8.1 (see config.ps1), source only
$qt = New-Object Tool("qt", "ftp://ftp.qt.nokia.com/qt/source/qt-everywhere-opensource-src-$script:CX_QT_VERSION.zip", "$ToolFolder\qt.zip", "ZIP", "$script:CX_EXTERNAL_CODE\Qt\qt-everywhere-opensource-src-$script:CX_QT_VERSION\bin", "$script:CX_EXTERNAL_CODE\Qt", "createpackage.bat", "Qt source code.")
# Boost 1.49.0
$boost = New-Object Tool("boost", "http://downloads.sourceforge.net/project/boost/boost/1.49.0/boost_1_49_0.zip?r=&ts=1340279004&use_mirror=dfn", "$ToolFolder\boost.zip", "ZIP", "$script:CX_EXTERNAL_CODE\boost_1_49_0", "$script:CX_EXTERNAL_CODE", "", "Utility library.")
# Console2 2.00b148Beta (x86)
$console2 = New-Object Tool("console2", "http://downloads.sourceforge.net/project/console/console-devel/2.00/Console-2.00b148-Beta_32bit.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fconsole%2F&ts=1345702855&use_mirror=garr", "$ToolFolder\console2.zip", "ZIP", "$script:CX_PROGRAM_FILES_X86\Console2", "$script:CX_PROGRAM_FILES_X86", "Console", "Console is a Windows console window enhancement.")
# ITK-SNAP 2.2.0 (x64)
$itksnap = New-Object Tool("ITK-Snap", "http://sourceforge.net/projects/itk-snap/files/itk-snap/2.2.0//itksnap-2.2.0-20110504-win64-x64.exe/download", "$ToolFolder\ITKSnap.exe", "NSIS package", "$script:CX_PROGRAM_FILES_X86\ITK-SNAP 2.2\bin", "", "InsightSNAP.exe", "Software application used to segment structures in 3D medical images.")
# Firefox 15.0 (US)
$firefox = New-Object Tool("firefox", "http://download.mozilla.org/?product=firefox-15.0&os=win&lang=en-US", "$ToolFolder\Firefox.exe", "UPX Packed executable", "$script:CX_PROGRAM_FILES_X86\Mozilla Firefox", "", "firefox", "The Internet browser.")

#Setup tool containers
#--------------
$AllTools = @($msvc2010Express, $7zip, $cppunit, $jom, $git, $svn, $cmake, $cuda, $nsis, $python, $perl, $qt, $boost, $eclipse, $console2, $itksnap, $firefox)
$SelectedTools = @()

#Create extended path and add to session
#--------------
$extendedPath = "$script:CX_EXTERNAL_CODE\cppunit-1.12.1\include" #Adding this so that CMake can find CppUnit
$extendedPath += ";$script:CX_PROGRAM_FILES\NVIDIA GPU Computing Toolkit\CUDA\v4.2\include" #Adding this so that FindOpenCL.cmake can find OpenCL
foreach($t in $AllTools){
    $extendedPath = $extendedPath+";"+$t.get_installedBinFolder()+""
}

#Parse parameters
#--------------
switch ($type)
{
    "developer" {
        $SelectedTools = @($firefox, $7zip, $cppunit, $jom, $svn, $git, $cmake, $cuda, $nsis, $python, $perl, $qt, $boost, $eclipse, $console2, $itksnap)
    }
    "minimum" {
        $SelectedTools = @($7zip, $cppunit, $jom, $git, $cmake, $python, $perl, $qt, $boost )
    }
    "full" {$SelectedTools = $AllTools}
    "partial" {
        foreach($selected_tool in $tools){
            foreach($available_tool in $AllTools){
                if($selected_tool -eq $available_tool.get_name()){
                    $SelectedTools +=  $available_tool
                }
            }
        }
    }
    default {Add-Logging 'ERROR' "Could not figure out which type $type is."; return "Default error"}
}


#Prompt to continue
#--------------
Add-Logging 'INFO' "You have selected the following tools:"
foreach($t in $SelectedTools){
    Add-Logging 'INFO' ("--"+$t.get_name()+"`t`t `""+$t.get_helpText()+"`"")
}
Write-Host "`n"
Add-Logging 'INFO' "You have selected the following actions:"
if((($mode -eq "all") -or ($mode -eq "download")))
    {Add-Logging 'INFO' "-- Downloading"}
if((($mode -eq "all") -or ($mode -eq "install")))
    {Add-Logging 'INFO' "-- Installing"}
if((($mode -eq "all") -or ($mode -eq "environment")))
    {Add-Logging 'INFO' "-- Setting up environment"}
    
$ready = Read-Host "`nContinue? y/n"
if($ready -ne "y")
    {return "quit"}

#Tell the user to relax and let the script do its job
#--------------
Add-Logging 'EMPHASIS' "Ready to run, you can go drink some coffee now. :)"
Add-Logging 'HEADER' "PREPARATIONS"

#Adding to session path so that we can search to see if tool exists
Add-ToPathSession $extendedPath

#Create folders
#--------------
if((($mode -eq "all") -or ($mode -eq "download")))
 {mkdir $ToolFolder -force | Out-Null}
if((($mode -eq "all") -or ($mode -eq "environment")))
 {mkdir $CxEnvFolder -force | Out-Null}

#Download and install tools
#--------------
Add-Logging 'HEADER' "DOWNLOAD AND INSTALL TOOLS"
for($i=0; $i -le $SelectedTools.Length -1;$i++)
{
    $tool = $SelectedTools[$i]
    
    if(Tool-Exists $tool)
        {continue}
        
    Add-Logging 'INFO' ("Missing tool "+$tool.get_name())
    
    #Downloading tool
    if((($mode -eq "all") -or ($mode -eq "download")))
    {
        if(!(Download-Tool $tool))
           {continue}
    }
    #Installing tool
    if((($mode -eq "all") -or ($mode -eq "install")))
    {
        if(!(Install-Tool $tool))
            {continue}
    }
    #Add to path to make tools avaiable in this session
    if(!(Add-ToPath $tool))
        {continue}
    
    #Configure git
    if($tool.get_name() -eq "git")
        {Configure-Git $script:CX_GIT_NAME $script:CX_GIT_EMAIL}
}

#Create batch files for setting up the developer environment
#--------------
Add-Logging 'HEADER' "ENVIRONMENT"

if((($mode -eq "all") -or ($mode -eq "environment")))
{
    #Check that prerequirements are met
    if(!(Test-MSVCInstalled)){
        Add-Logging 'ERROR' "You need to have Microsoft Visual Studio 2010 installed before setting up a environment."
        return "Abort"
    }
    
    # create 32bit CustusX environment for cmd
    Create-Cx-Environment $script:CX_CXVARS_86 "x86" $extendedPath 
    
    # create 64bit CustusX environment for cmd 
    Create-Cx-Environment $script:CX_CXVARS_64 "x64" $extendedPath 
    
    # create shortcut that loads eclipse and cmake in correct environment
    # they will only run in a 64 bit environment
    foreach($t in $SelectedTools){
        if(($t.get_name() -eq "cmake") -or ($t.get_name() -eq "eclipse")){
            if(!(Create-Batch-Exe $t.get_executableName() $script:CX_CXVARS_64 $CxEnvFolder)){
                Add-Logging 'WARNING' ("Could not create 64 bit shortcut and batch file for "+$t.get_name())
            }
            if(!(Create-Batch-Exe $t.get_executableName() $script:CX_CXVARS_86 $CxEnvFolder)){
                Add-Logging 'WARNING' ("Could not create 32 bit shortcut and batch file for "+$t.get_name())
            }
        }
        if($t.get_name() -eq "git"){
            Add-Console2Tab -TabTitle "Git Bash" -ConsoleShell "cmd.exe /c &quot;&quot;$script:CX_PROGRAM_FILES_X86\Git\bin\sh.exe&quot; --login -i&quot;" -InitalDir "$script:CX_WORKSPACE\CustusX3" -SaveSettingsToUserDir $true -Icon "$script:CX_PROGRAM_FILES_X86\Git\etc\git.ico"
        }
    }

    # create shortcut to powershell.exe with cx environment
    # will only run in 64 bit environment
    $powershellExecutableName = "powershell"
    Create-Batch-Exe $powershellExecutableName $script:CX_CXVARS_86 $CxEnvFolder | Out-Null
    Create-Batch-Exe $powershellExecutableName $script:CX_CXVARS_64 $CxEnvFolder | Out-Null
    
    # add cmd tab to console 2
    Add-Console2Tab -TabTitle "Cmd" -ConsoleShell "cmd" -InitalDir "$script:CX_WORKSPACE" -SaveSettingsToUserDir $true
}
return $true
}
