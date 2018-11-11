#usage initialize.ps1
param
(
    [string] $templateLink              = "https://raw.githubusercontent.com/Microsoft/nav-arm-templates/master/buildagent.json",
    [Parameter(Mandatory=$true)]
    [string] $vmAdminUsername,
    [Parameter(Mandatory=$true)]
    [string] $adminPassword,
    [Parameter(Mandatory=$true)]
    [string] $devopsorganization,
    [Parameter(Mandatory=$true)]
    [string] $personalaccesstoken,
    [Parameter(Mandatory=$true)]
    [string] $pool,
    [Parameter(Mandatory=$true)]
    [string] $vmname
)

function Download-File([string]$sourceUrl, [string]$destinationFile)
{
    Log "Downloading $destinationFile"
    Remove-Item -Path $destinationFile -Force -ErrorAction Ignore
    (New-Object System.Net.WebClient).DownloadFile($sourceUrl, $destinationFile)
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12

Set-ExecutionPolicy -ExecutionPolicy unrestricted -Force

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 | Out-Null

if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -WarningAction Ignore | Out-Null
}

Install-Module -Name navcontainerhelper -Force
Import-Module -Name navcontainerhelper -DisableNameChecking

Install-module DockerMsftProvider -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

$DownloadFolder = "C:\Download"
MkDir $DownloadFolder -ErrorAction Ignore | Out-Null
$agentFilename = "vsts-agent-win-x64-2.141.1.zip"
$agentFullname = Join-Path $DownloadFolder $agentFilename
$agentUrl = "https://vstsagentpackage.azureedge.net/agent/2.141.1/$agentFilename"
Download-File -sourceUrl $agentUrl -destinationFile $agentFullname
$agentFolder = "C:\Agent"
mkdir $agentFolder -ErrorAction Ignore | Out-Null
cd $agentFolder
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($agentFullname, $agentFolder)

.\config.cmd --unattended --url "$devopsorganization" --auth PAT --token "$personalaccesstoken" --pool "$pool" --agent "$vmname" --runAsService --windowsLogonAccount $vmAdminUsername --windowsLogonPassword $adminPassword

Restart-Computer -force
