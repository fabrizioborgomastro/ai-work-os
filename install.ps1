[CmdletBinding()]
param(
    [ValidateSet("kilo", "opencode", "pi", "codex", "claude", "generic")]
    [string]$Client,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bootstrap = Join-Path $root "scripts\bootstrap.py"

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

$python = Get-Command py -ErrorAction SilentlyContinue
$pythonArgs = @()
if ($python) {
    $pythonArgs += "-3"
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
}

if (-not $python) {
    throw "Python 3 is required. Install it, reopen PowerShell and run this command again."
}

$pythonArgs += $bootstrap
$pythonArgs += "--client"
$pythonArgs += $Client
if (-not $DryRun) {
    $pythonArgs += "--apply"
}

Write-Host "AI Work OS root: $root"
Write-Host "Selected client: $Client"
if ($DryRun) {
    Write-Host "Mode: dry run (no files will be changed)"
} else {
    Write-Host "Mode: install"
}

& $python.Source @pythonArgs
if ($LASTEXITCODE -ne 0) {
    throw "AI Work OS bootstrap failed with exit code $LASTEXITCODE."
}

if (-not $DryRun) {
    $report = Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    Write-Host ""
    Write-Host "Installation complete." -ForegroundColor Green
    Write-Host "Manual steps report: $report"
}
