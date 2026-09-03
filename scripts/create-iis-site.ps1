<#
Create an IIS AppPool and Website and set folder permissions.

Usage (run as Administrator on the IIS server):
  .\create-iis-site.ps1 -SiteName 'MyApp-Dev' -AppPool 'MyAppPool-Dev' -PhysicalPath 'C:\inetpub\wwwroot\MyApp-Dev' -Port 80
#>

param(
	[Parameter(Mandatory=$true)] [string] $SiteName,
	[Parameter(Mandatory=$true)] [string] $AppPool,
	[Parameter(Mandatory=$true)] [string] $PhysicalPath,
	[int] $Port = 80
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module WebAdministration -ErrorAction Stop

Write-Output "Ensuring physical path exists: $PhysicalPath"
if (-not (Test-Path $PhysicalPath)) { New-Item -ItemType Directory -Path $PhysicalPath -Force | Out-Null }

# Create AppPool if missing
if (-not (Get-WebAppPoolState -Name $AppPool -ErrorAction SilentlyContinue)) {
	Write-Output "Creating application pool: $AppPool"
	New-WebAppPool -Name $AppPool
	# Set to ApplicationPoolIdentity
	Set-ItemProperty "IIS:\AppPools\$AppPool" -Name processModel.identityType -Value "ApplicationPoolIdentity"
} else {
	Write-Output "AppPool $AppPool already exists"
}

# Create website if missing
if (-not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
	Write-Output "Creating website: $SiteName (Port $Port)"
	New-Website -Name $SiteName -Port $Port -PhysicalPath $PhysicalPath -ApplicationPool $AppPool
} else {
	Write-Output "Website $SiteName already exists - updating physical path and app pool"
	Set-ItemProperty "IIS:\Sites\$SiteName" -Name physicalPath -Value $PhysicalPath
	Set-ItemProperty "IIS:\Sites\$SiteName" -Name applicationPool -Value $AppPool
}

# Set permissions for IIS
try {
	Write-Output "Setting permissions for IIS_IUSRS on $PhysicalPath"
	icacls $PhysicalPath /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null
} catch {
	Write-Warning "Failed to set permissions: $_"
}

Write-Output "IIS site and app pool creation/config complete"
