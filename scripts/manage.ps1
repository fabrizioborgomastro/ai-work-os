[CmdletBinding(DefaultParameterSetName = "Status")]
param(
    [Parameter(ParameterSetName = "Doctor")][switch]$Doctor,
    [Parameter(ParameterSetName = "Status")][switch]$Status,
    [Parameter(ParameterSetName = "Compatibility")][switch]$Compatibility,
    [Parameter(ParameterSetName = "Update")][switch]$Update,
    [Parameter(ParameterSetName = "Uninstall")][switch]$Uninstall,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$stateRoot = $PSScriptRoot
$manifestPath = Join-Path $stateRoot "install.json"

function Read-Installation {
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "AI Work OS installation manifest not found: $manifestPath"
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
    if ($manifest.schemaVersion -notin @(1, 2)) {
        throw "Unsupported installation manifest schema: $($manifest.schemaVersion)"
    }
    if (-not (Test-Path -LiteralPath $manifest.ledger -PathType Leaf)) {
        throw "Managed-files ledger not found: $($manifest.ledger)"
    }
    $files = @(Import-Csv -LiteralPath $manifest.ledger -Delimiter "|")
    return @{ Manifest = $manifest; Files = $files }
}

function Show-Compatibility {
    $installation = Read-Installation
    $manifest = $installation.Manifest
    if ($manifest.schemaVersion -lt 2) {
        Write-Host "Compatibility data unavailable: reinstall or update AI Work OS to migrate the manifest." -ForegroundColor Yellow
        return
    }
    Write-Host "Host/editor: $($manifest.host) (informational only)"
    Write-Host "Target runtime: $($manifest.target)"
    Write-Host "Adapter: $($manifest.adapter)"
    Write-Host "Workflow compatibility: $($manifest.workflowCompatibility)"
    Write-Host "Routing compatibility: $($manifest.routingCompatibility)"
    Write-Host "Catalog verified: $($manifest.compatibilityVerified)"
    Write-Host "Report: $($manifest.report)"
}

function Get-FileState($Entry) {
    if (-not (Test-Path -LiteralPath $Entry.path -PathType Leaf)) { return "missing" }
    $hash = (Get-FileHash -LiteralPath $Entry.path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -eq $Entry.installedHash) { return "unchanged" }
    return "modified"
}

function Remove-OrRestoreEntry($Entry) {
    $state = Get-FileState $Entry
    if ($state -eq "modified") {
        Write-Host "PRESERVE modified: $($Entry.path)"
        return $false
    }
    if ($state -eq "missing") { return $true }
    $hasBackup = $Entry.backupPath -and (Test-Path -LiteralPath $Entry.backupPath -PathType Leaf)
    if ($Entry.preExisting -eq "1" -and $hasBackup) {
        Write-Host "RESTORE: $($Entry.backupPath) -> $($Entry.path)"
        if (-not $DryRun) {
            Copy-Item -LiteralPath $Entry.backupPath -Destination $Entry.path -Force
            Remove-Item -LiteralPath $Entry.backupPath -Force
        }
        return $true
    }
    if ($Entry.preExisting -eq "1") {
        Write-Host "PRESERVE pre-existing (no backup recorded): $($Entry.path)"
        return $false
    }
    Write-Host "REMOVE: $($Entry.path)"
    if (-not $DryRun) { Remove-Item -LiteralPath $Entry.path -Force }
    return $true
}

function Show-Status([bool]$Detailed) {
    $installation = Read-Installation
    $manifest = $installation.Manifest
    $counts = @{ unchanged = 0; modified = 0; missing = 0 }
    foreach ($entry in $installation.Files) {
        $state = Get-FileState $entry
        $counts[$state]++
        if ($Detailed -and $state -ne "unchanged") {
            Write-Host "[$($state.ToUpperInvariant())] $($entry.path)"
        }
    }
    $rootState = if (Test-Path -LiteralPath $manifest.root -PathType Container) { "present" } else { "missing" }
    Write-Host "Client: $($manifest.client)"
    Write-Host "Source: $($manifest.root) ($rootState)"
    Write-Host "Revision: $($manifest.sourceRevision)"
    Write-Host "Managed files: $($installation.Files.Count)"
    Write-Host "Unchanged: $($counts.unchanged); modified: $($counts.modified); missing: $($counts.missing)"
    if ($rootState -eq "present" -and $counts.modified -eq 0 -and $counts.missing -eq 0) {
        Write-Host "State: OK" -ForegroundColor Green
        return 0
    }
    Write-Host "State: ACTION REQUIRED" -ForegroundColor Yellow
    return 1
}

function Invoke-Uninstall {
    $installation = Read-Installation
    $preserved = 0
    $deferred = [System.Collections.Generic.List[object]]::new()
    foreach ($entry in $installation.Files) {
        if ($entry.path -eq $PSCommandPath -or $entry.path -eq $installation.Manifest.report) {
            $deferred.Add($entry)
            continue
        }
        if (-not (Remove-OrRestoreEntry $entry)) { $preserved++ }
    }
    if ($DryRun) {
        foreach ($entry in $deferred) { [void](Remove-OrRestoreEntry $entry) }
        Write-Host "Dry run complete; no files changed."
        return
    }
    if ($preserved -gt 0) {
        Write-Host "Uninstall incomplete: $preserved user or pre-existing file(s) preserved. Manager and state files retained for recovery." -ForegroundColor Yellow
        return
    }
    foreach ($entry in $deferred) {
        if (-not (Remove-OrRestoreEntry $entry)) {
            Write-Host "Management state was preserved because a lifecycle file could not be safely removed." -ForegroundColor Yellow
            return
        }
    }
    foreach ($path in @($installation.Manifest.ledger, $manifestPath)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force }
    }
    Write-Host "AI Work OS uninstalled. Empty parent directories may remain."
}

function Invoke-Update {
    $installation = Read-Installation
    $installer = Join-Path $installation.Manifest.root "install.ps1"
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
        throw "Source installer not found. Restore or re-clone the distribution at: $($installation.Manifest.root)"
    }
    $arguments = @{ Target = $installation.Manifest.client; HostApp = $(if ($installation.Manifest.host) { $installation.Manifest.host } else { "auto" }) }
    if ($installation.Manifest.skillPath) { $arguments.SkillPath = $installation.Manifest.skillPath }
    if ($installation.Manifest.schemaVersion -ge 2 -and -not $installation.Manifest.compatibilityVerified) {
        $arguments.AcceptUnverified = $true
        $arguments.WorkflowCapability = $installation.Manifest.workflowCompatibility
        $arguments.RoutingCapability = $installation.Manifest.routingCompatibility
    } elseif (($installation.Manifest.schemaVersion -ge 2 -and $installation.Manifest.workflowCompatibility -ne "native") -or
              ($installation.Manifest.schemaVersion -eq 1 -and $installation.Manifest.client -in @("pi", "codex", "claude"))) {
        $arguments.AcceptLimitedCompatibility = $true
    }
    if ($DryRun) { $arguments.Analyze = $true }
    & $installer @arguments
}

if ($Doctor) { [void](Show-Status $true); return }
if ($Compatibility) { Show-Compatibility; return }
if ($Update) { Invoke-Update; return }
if ($Uninstall) { Invoke-Uninstall; return }
[void](Show-Status $false)
