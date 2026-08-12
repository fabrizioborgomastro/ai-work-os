[CmdletBinding(DefaultParameterSetName = "Status")]
param(
    [Parameter(ParameterSetName = "Doctor")][switch]$Doctor,
    [Parameter(ParameterSetName = "Status")][switch]$Status,
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
    if ($manifest.schemaVersion -ne 1) {
        throw "Unsupported installation manifest schema: $($manifest.schemaVersion)"
    }
    if (-not (Test-Path -LiteralPath $manifest.ledger -PathType Leaf)) {
        throw "Managed-files ledger not found: $($manifest.ledger)"
    }
    $files = @(Import-Csv -LiteralPath $manifest.ledger -Delimiter "|")
    return @{ Manifest = $manifest; Files = $files }
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
    if ($DryRun) {
        & $installer -Client $installation.Manifest.client -DryRun
    } else {
        & $installer -Client $installation.Manifest.client
    }
}

if ($Doctor) { [void](Show-Status $true); return }
if ($Update) { Invoke-Update; return }
if ($Uninstall) { Invoke-Uninstall; return }
[void](Show-Status $false)
