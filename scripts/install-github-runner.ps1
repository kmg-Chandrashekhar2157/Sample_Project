<#
Usage:
  1. Create a repository runner registration token in GitHub: Settings -> Actions -> Runners -> New self-hosted runner -> Generate token
  2. Run on the target Windows server (PowerShell as Administrator):
	   .\install-github-runner.ps1 -RepoUrl 'https://github.com/OWNER/REPO' -Token 'YOUR_TOKEN' -RunnerName 'dev-runner' -Labels 'self-hosted,windows,dev'

This script downloads the official GitHub Actions runner, configures it non-interactively, installs it as a service, and starts it.
#>

param(
	[Parameter(Mandatory=$true)] [string] $RepoUrl,
	[Parameter(Mandatory=$true)] [string] $Token,
	[string] $RunnerName = "$env:COMPUTERNAME-sample project-dev",
	[string] $Labels = 'self-hosted,windows,dev'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installDir = 'C:\actions-runner'
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

Write-Host "Installing GitHub Actions runner to $installDir"
Push-Location $installDir

$zipUrl = 'https://github.com/actions/runner/releases/latest/download/actions-runner-win-x64.zip'
$zipPath = Join-Path $installDir 'actions-runner.zip'

Write-Host "Downloading runner from $zipUrl"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

Write-Host "Extracting runner"
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
Remove-Item $zipPath

Write-Host "Configuring runner (non-interactive)"
& .\config.cmd --unattended --url $RepoUrl --token $Token --name $RunnerName --labels $Labels --work _work

Write-Host "Installing runner service"
& .\svc.sh install
& .\svc.sh start

Write-Host "Runner installed and started. Verify in GitHub repository Settings -> Actions -> Runners"
Pop-Location
