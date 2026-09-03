param(
	[Parameter(Mandatory=$true)] [string] $ArtifactPath,
	[Parameter(Mandatory=$true)] [string] $SiteName,
	[Parameter(Mandatory=$true)] [string] $AppPool,
	[Parameter(Mandatory=$true)] [string] $DeployPath
)

try {
	Write-Output "Deploy started: ArtifactPath=$ArtifactPath, SiteName=$SiteName, AppPool=$AppPool, DeployPath=$DeployPath"

	Import-Module WebAdministration -ErrorAction Stop

	# Stop app pool
	Write-Output "Stopping AppPool: $AppPool"
	if (Get-WebAppPoolState -Name $AppPool -ErrorAction SilentlyContinue) {
		Stop-WebAppPool -Name $AppPool -ErrorAction Continue
	}

	# Backup current site (optional)
	$timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
	$backupRoot = "C:\inetpub\backups"
	$backupPath = Join-Path $backupRoot "$SiteName-$timestamp"
	Write-Output "Backing up current site to $backupPath"
	New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
	if (Test-Path $DeployPath) {
		robocopy $DeployPath $backupPath /MIR | Out-Null
	}

	# Ensure deploy folder exists
	Write-Output "Preparing deploy path: $DeployPath"
	New-Item -ItemType Directory -Force -Path $DeployPath | Out-Null

	# Remove existing files and copy new ones
	Write-Output "Deploying files from $ArtifactPath to $DeployPath"
	robocopy $ArtifactPath $DeployPath /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null

	# (Optional) Set permissions so IIS can read
	try {
		icacls $DeployPath /grant "IIS_IUSRS:(OI)(CI)RX" /T | Out-Null
	} catch {
		Write-Warning "Failed to set permissions: $_"
	}

	# Start app pool
	Write-Output "Starting AppPool: $AppPool"
	Start-WebAppPool -Name $AppPool -ErrorAction Continue

	Write-Output "Deployment completed successfully"
	exit 0
}
catch {
	Write-Error "Deployment failed: $_"
	exit 1
}
