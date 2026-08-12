[CmdletBinding()]
param(
    [Alias("Client")][string]$Target,
    [Alias("Host")][string]$HostApp = "auto",
    [string]$SkillPath,
    [ValidateSet("unknown", "native", "adapted", "skill-only", "unsupported")]
    [string]$WorkflowCapability = "unknown",
    [ValidateSet("unknown", "native-combo", "external-manual", "unsupported")]
    [string]$RoutingCapability = "unknown",
    [Alias("DryRun")][switch]$Analyze,
    [switch]$AcceptLimitedCompatibility,
    [switch]$AcceptUnverified
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bootstrap = Join-Path $root "scripts\bootstrap.ps1"
if (-not (Test-Path -LiteralPath $bootstrap -PathType Leaf)) { throw "Bootstrap not found: $bootstrap" }

$arguments = @{ HostApp = $HostApp; WorkflowCapability = $WorkflowCapability; RoutingCapability = $RoutingCapability }
if ($Target) { $arguments.Target = $Target }
if ($SkillPath) { $arguments.SkillPath = $SkillPath }
if (-not $Analyze) { $arguments.Apply = $true }
if ($AcceptLimitedCompatibility) { $arguments.AcceptLimitedCompatibility = $true }
if ($AcceptUnverified) { $arguments.AcceptUnverified = $true }

Write-Host "AI Work OS root: $root"
Write-Host "Installer engine: PowerShell (Python is not required)"
Write-Host $(if ($Analyze) { "Mode: compatibility analysis (no files will be changed)" } else { "Mode: install after compatibility preflight" })
& $bootstrap @arguments

if (-not $Analyze) {
    $report = Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    Write-Host ""
    Write-Host "Installation complete." -ForegroundColor Green
    Write-Host "Manual steps report: $report"
}
