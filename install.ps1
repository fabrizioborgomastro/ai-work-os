[CmdletBinding()]
param(
    [ValidateSet("kilo", "opencode", "pi", "codex", "claude", "generic")]
    [string]$Client,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bootstrap = Join-Path $root "scripts\bootstrap.ps1"

if (-not (Test-Path -LiteralPath $bootstrap -PathType Leaf)) {
    throw "Bootstrap not found: $bootstrap"
}

if (-not $Client) {
    Write-Host "Specify the agentic client to install:" -ForegroundColor Cyan
    Write-Host "  kilo | opencode | pi | codex | claude | generic"
    Write-Host ""
    Write-Host "Example: powershell -ExecutionPolicy Bypass -File .\install.ps1 -Client kilo"
    exit 2
}

Write-Host "AI Work OS root: $root"
Write-Host "Selected client: $Client"
Write-Host "Installer engine: PowerShell (Python is not required)"
if ($DryRun) {
    Write-Host "Mode: dry run (no files will be changed)"
} else {
    Write-Host "Mode: install"
}

if ($DryRun) {
    & $bootstrap -Client $Client
} else {
    & $bootstrap -Client $Client -Apply
}
if (-not $DryRun) {
    $report = Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    Write-Host ""
    Write-Host "Installation complete." -ForegroundColor Green
    Write-Host "Manual steps report: $report"
}
