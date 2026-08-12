[CmdletBinding()]
param(
    [Alias("Client")][string]$Target,
    [Alias("Host")][string]$HostApp = "auto",
    [string]$SkillPath,
    [ValidateSet("unknown", "native", "adapted", "skill-only", "unsupported")]
    [string]$WorkflowCapability = "unknown",
    [ValidateSet("unknown", "native-combo", "external-manual", "unsupported")]
    [string]$RoutingCapability = "unknown",
    [switch]$AcceptLimitedCompatibility,
    [switch]$AcceptUnverified,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$distributionRoot = Split-Path -Parent $PSScriptRoot
$catalogPath = Join-Path $distributionRoot "adapters\compatibility.tsv"
$catalog = @(Import-Csv -LiteralPath $catalogPath -Delimiter "|")
$runtimeRows = @($catalog | Where-Object kind -eq "runtime")
$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$managedFiles = [System.Collections.Generic.List[object]]::new()
$previousManaged = @{}
$previousManifestPath = Join-Path $HOME ".ai-work-os\install.json"

if (Test-Path -LiteralPath $previousManifestPath -PathType Leaf) {
    try {
        $previousManifest = Get-Content -LiteralPath $previousManifestPath -Raw -Encoding utf8 | ConvertFrom-Json
        if ($previousManifest.ledger -and (Test-Path -LiteralPath $previousManifest.ledger -PathType Leaf)) {
            foreach ($entry in Import-Csv -LiteralPath $previousManifest.ledger -Delimiter "|") {
                $previousManaged[$entry.path.ToLowerInvariant()] = $entry
            }
        }
    } catch {
        throw "Existing AI Work OS installation state is unreadable. Run the installed manager with -Doctor before reinstalling. $($_.Exception.Message)"
    }
}

$roleNames = @("business-wayfinder", "business-engineer", "business-architect", "business-reviewer", "light-planner", "light-builder", "light-reviewer")
$routeNames = @("business-engineering", "business-review", "light-engineering", "light-review")

function Get-DetectedRuntimes {
    $found = @()
    foreach ($row in $runtimeRows) {
        if ($row.command -and (Get-Command $row.command -ErrorAction SilentlyContinue)) { $found += $row.id }
    }
    return @($found | Select-Object -Unique)
}

function Resolve-Host([string]$Requested) {
    if ($Requested -and $Requested -ne "auto") { return $Requested.ToLowerInvariant() }
    if ($env:CURSOR_TRACE_ID -or $env:TERM_PROGRAM -eq "cursor") { return "cursor" }
    if ($env:ANTIGRAVITY_HOME -or $env:ANTIGRAVITY_SESSION) { return "antigravity" }
    if ($env:VSCODE_PID -or $env:TERM_PROGRAM -eq "vscode") { return "vscode" }
    return "terminal"
}

function Resolve-Target([string]$Requested, [string[]]$Detected) {
    if ($Requested) { return $Requested.ToLowerInvariant() }
    if ($env:AI_WORK_OS_TARGET) { return $env:AI_WORK_OS_TARGET.ToLowerInvariant() }
    if ($Detected.Count -eq 1) { return $Detected[0] }
    $detectedText = if ($Detected.Count) { $Detected -join ", " } else { "none" }
    throw "The target runtime is ambiguous; detected: $detectedText. Use -Target <runtime>. The host/editor is never used as an implicit target."
}

function Get-SkillBase([string]$SelectedTarget, $Compatibility) {
    if (-not $Compatibility) { return [System.IO.Path]::GetFullPath($SkillPath) }
    switch ($SelectedTarget) {
        "kilo" { return Join-Path $HOME ".kilo\skills" }
        "opencode" { return Join-Path $HOME ".config\opencode\skills" }
        "pi" { return Join-Path $HOME ".pi\agent\skills" }
        "codex" { return Join-Path $HOME ".codex\skills" }
        "claude" { return Join-Path $HOME ".claude\skills" }
    }
    throw "No verified skill destination for target: $SelectedTarget"
}

function Get-ClientTargets([string]$SelectedTarget, $Compatibility) {
    $targets = @()
    if ($SelectedTarget -eq "kilo") { $targets += Join-Path $HOME ".config\kilo\agents" }
    elseif ($SelectedTarget -eq "opencode") { $targets += Join-Path $HOME ".config\opencode\agents" }
    $skillBase = Get-SkillBase $SelectedTarget $Compatibility
    $targets += Join-Path $skillBase "ai-work-os"
    $targets += Join-Path $skillBase "wayfinder"
    if ($SelectedTarget -eq "pi") { $targets += Join-Path $HOME ".pi\agent\prompts" }
    $targets += Join-Path $HOME ".ai-work-os\manage.ps1"
    $targets += Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    $targets += Join-Path $HOME ".ai-work-os\install.json"
    $targets += Join-Path $HOME ".ai-work-os\managed-files.tsv"
    return @($targets)
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Register-ManagedFile([string]$Path, [bool]$PreExisting, [string]$BackupPath) {
    if ($Path.Contains("|") -or $Path.Contains("`n") -or $Path.Contains("`r")) { throw "Managed paths cannot contain pipes or newlines: $Path" }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $previous = $previousManaged[$fullPath.ToLowerInvariant()]
    if ($previous) {
        $PreExisting = $previous.preExisting -eq "1"
        if (-not $BackupPath) { $BackupPath = $previous.backupPath }
    }
    $managedFiles.Add([ordered]@{
        path = $fullPath
        installedHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
        preExisting = $PreExisting
        backupPath = $BackupPath
    })
}

function Backup-AndWrite([string]$Path, [string]$Content, [switch]$Track) {
    $preExisting = Test-Path -LiteralPath $Path -PathType Leaf
    $backupPath = ""
    if ($preExisting) {
        $existing = [System.IO.File]::ReadAllText($Path)
        if ($existing -ne $Content) { $backupPath = "$Path.backup-$stamp"; Copy-Item -LiteralPath $Path -Destination $backupPath -Force }
    }
    Write-Utf8NoBom $Path $Content
    if ($Track) { Register-ManagedFile $Path $preExisting $backupPath }
}

function Install-Skills([string]$SelectedTarget, $Compatibility) {
    $skillBase = Get-SkillBase $SelectedTarget $Compatibility
    $portableRoot = $distributionRoot.Replace("\", "/")
    $skillContent = [System.IO.File]::ReadAllText((Join-Path $distributionRoot "skills\ai-work-os\SKILL.md")).Replace("{{AI_WORK_OS_HOME}}", $portableRoot)
    Backup-AndWrite (Join-Path $skillBase "ai-work-os\SKILL.md") $skillContent -Track
    $wayfinderSource = Join-Path $distributionRoot "third_party\mattpocock-wayfinder"
    foreach ($name in @("SKILL.md", "LICENSE", "README.md")) {
        Backup-AndWrite (Join-Path $skillBase "wayfinder\$name") ([System.IO.File]::ReadAllText((Join-Path $wayfinderSource $name))) -Track
    }
}

function Install-MarkdownAgents([string]$SelectedTarget) {
    $targetPath = if ($SelectedTarget -eq "kilo") { Join-Path $HOME ".config\kilo\agents" } else { Join-Path $HOME ".config\opencode\agents" }
    $source = Join-Path $distributionRoot "adapters\markdown-agents\agents"
    $portableRoot = $distributionRoot.Replace("\", "/")
    foreach ($file in Get-ChildItem -LiteralPath $source -Filter "*.md" -File | Sort-Object Name) {
        $content = [System.IO.File]::ReadAllText($file.FullName).Replace('`core/', ('`' + $portableRoot + '/core/')).Replace('`templates/', ('`' + $portableRoot + '/templates/'))
        Backup-AndWrite (Join-Path $targetPath $file.Name) $content -Track
    }
}

function Install-PiPrompts {
    $targetPath = Join-Path $HOME ".pi\agent\prompts"
    $portableRoot = $distributionRoot.Replace("\", "/")
    foreach ($role in $roleNames) {
        $content = "Activate the AI Work OS ``$role`` role for the project in the current working directory.`n`nRead and follow ``$portableRoot/core/agents/$role.md`` and the shared policies under ``$portableRoot/core/``. Treat ``$portableRoot`` as read-only. Persist all operational artifacts and handoffs in the actual project.`n"
        Backup-AndWrite (Join-Path $targetPath "ai-$role.md") $content -Track
    }
}

function Get-ClientConfigText([string]$SelectedTarget) {
    $candidates = switch ($SelectedTarget) {
        "kilo" { @(Join-Path $HOME ".config\kilo\kilo.jsonc") }
        "opencode" { @((Join-Path $HOME ".config\opencode\opencode.json"), (Join-Path $HOME ".config\opencode\opencode.jsonc")) }
        "pi" { @(Join-Path $HOME ".pi\agent\models.json") }
        default { @() }
    }
    return (@($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | ForEach-Object { [System.IO.File]::ReadAllText($_) }) -join "`n")
}

function Get-RoutingNotice([string]$RoutingLevel) {
    switch ($RoutingLevel) {
        "native-combo" {
            return [ordered]@{
                Status = "CAPABLE - configuration not verified"
                Combo = "Available only after the runtime combos and providers are configured and tested"
                Action = "Verify the four routes in core/ROUTING.md; the installer does not create provider or combo configuration"
            }
        }
        "external-manual" {
            return [ordered]@{
                Status = "NOT CONFIGURED"
                Combo = "Unavailable until a compatible routing layer is configured"
                Action = "Configure OmniRoute, an equivalent external router, or a supported manual runtime mapping"
            }
        }
        "unsupported" {
            return [ordered]@{ Status = "UNSUPPORTED"; Combo = "Unavailable"; Action = "Use a runtime or router that can implement the four logical routes" }
        }
        default {
            return [ordered]@{ Status = "UNKNOWN"; Combo = "Not verified"; Action = "Verify routing capabilities before relying on combos, fallbacks or review panels" }
        }
    }
}

function New-SetupReport([string]$SelectedTarget, [string]$SelectedHost, $Compatibility, [string[]]$Detected, [bool]$Verified) {
    $workflow = if ($Compatibility) { $Compatibility.workflowLevel } else { $WorkflowCapability }
    $routing = if ($Compatibility) { $Compatibility.routingLevel } else { $RoutingCapability }
    $routingNotice = Get-RoutingNotice $routing
    $adapter = if ($Compatibility) { $Compatibility.adapter } else { "generic-explicit" }
    $limitation = if ($Compatibility) { $Compatibility.limitation } else { "Capacita dichiarate dall'utente e non verificate dal catalogo." }
    $recommendation = if ($Compatibility) { $Compatibility.recommendation } else { "Verificare la documentazione ufficiale del runtime prima dell'uso reale." }
    $evidence = if ($Compatibility) { "$($Compatibility.evidence) (verificato $($Compatibility.verifiedAt))" } else { "UNKNOWN: runtime non presente nel catalogo locale" }
    $targetsText = (Get-ClientTargets $SelectedTarget $Compatibility | ForEach-Object { "- ``$_``" }) -join "`n"
    $detectedText = if ($Detected.Count) { $Detected -join ", " } else { "none" }
    $configText = Get-ClientConfigText $SelectedTarget
    $missingRoutes = @($routeNames | Where-Object { -not $configText.Contains($_) })
    $missingText = if ($missingRoutes.Count) { ($missingRoutes | ForEach-Object { "- ``$_``" }) -join "`n" } else { "- none detected" }
    return @"
# AI Work OS setup report

- Status: **APPLIED**
- Host/editor: ``$SelectedHost`` (informational; no files installed in the host)
- Target runtime: ``$SelectedTarget``
- Adapter: ``$adapter``
- Workflow compatibility: **$workflow**
- Routing compatibility: **$routing**
- Multiprovider routing: **$($routingNotice.Status)**
- Combo support: **$($routingNotice.Combo)**
- Catalog verification: **$Verified**
- Runtimes detected on PATH: $detectedText
- Installation scope: only ``$SelectedTarget``
- Canonical core: ``$distributionRoot``

## What was installed

$targetsText

## What was not installed or configured

- No files for other agentic clients or host editors.
- No provider, credential, plugin, MCP, combo, fallback, privacy control or spending limit.
- Routing action required: $($routingNotice.Action).
- Limitation: $limitation
- Recommendation: $recommendation
- Evidence: $evidence

## Route names not found in inspected runtime configuration

$missingText

This textual check is not proof that routes or providers work. A route may live in an external router.

## Lifecycle commands

- ``& \"$HOME\.ai-work-os\manage.ps1\" -Status``
- ``& \"$HOME\.ai-work-os\manage.ps1\" -Compatibility``
- ``& \"$HOME\.ai-work-os\manage.ps1\" -Doctor``
- ``& \"$HOME\.ai-work-os\manage.ps1\" -Update -DryRun``
- ``& \"$HOME\.ai-work-os\manage.ps1\" -Uninstall -DryRun``

Configure credentials through the runtime's secure flow. Verify privacy, provider and budget policies before sending real project data.
"@
}

$detectedRuntimes = @(Get-DetectedRuntimes)
$selectedHost = Resolve-Host $HostApp
$selectedTarget = Resolve-Target $Target $detectedRuntimes
$compatibility = $runtimeRows | Where-Object id -eq $selectedTarget | Select-Object -First 1
$verified = $null -ne $compatibility -and $selectedTarget -ne "generic"

if ($compatibility -and $selectedTarget -ne "generic") {
    $workflow = $compatibility.workflowLevel
    $routing = $compatibility.routingLevel
    $adapter = $compatibility.adapter
    $limitation = $compatibility.limitation
    $recommendation = $compatibility.recommendation
} else {
    $compatibility = $null
    $workflow = $WorkflowCapability
    $routing = $RoutingCapability
    $adapter = "generic-explicit"
    $limitation = "Runtime non catalogato: percorso e capacita non sono verificati automaticamente."
    $recommendation = "Fornire -SkillPath e verificare la documentazione ufficiale del runtime."
}

Write-Host ""
Write-Host "Compatibility preflight" -ForegroundColor Cyan
Write-Host "Host/editor: $selectedHost (informational only)"
Write-Host "Target runtime: $selectedTarget"
Write-Host "Adapter: $adapter"
Write-Host "Workflow compatibility: $workflow"
Write-Host "Routing compatibility: $routing"
$routingNotice = Get-RoutingNotice $routing
Write-Host "Multiprovider routing: $($routingNotice.Status)"
Write-Host "Combo support: $($routingNotice.Combo)"
Write-Host "Routing action: $($routingNotice.Action)"
Write-Host "Catalog status: $(if ($verified) { 'VERIFIED' } else { 'UNVERIFIED' })"
Write-Host "Limitation: $limitation"
Write-Host "Recommendation: $recommendation"

if (-not $verified) {
    $commandEvidence = if (Get-Command $selectedTarget -ErrorAction SilentlyContinue) { "VERIFIED: command found on PATH" } else { "UNKNOWN: command not found on PATH" }
    $pathEvidence = if ($SkillPath) { "INFERRED: user supplied skill path $SkillPath" } else { "UNKNOWN: no skill destination supplied" }
    Write-Host "Minimum audit:"
    Write-Host "- Executable: $commandEvidence"
    Write-Host "- Skill destination: $pathEvidence"
    Write-Host "- Workflow claim: INFERRED ($WorkflowCapability)"
    Write-Host "- Routing claim: INFERRED ($RoutingCapability)"
}

if ($Apply -and -not $verified) {
    if (-not $SkillPath) { throw "Unverified target blocked: provide an explicit -SkillPath. No files were changed." }
    if (-not $AcceptUnverified) { throw "Unverified target blocked: re-run with -AcceptUnverified after reviewing the audit. No files were changed." }
    if ($WorkflowCapability -eq "unsupported") { throw "The declared workflow capability is unsupported. No files were changed." }
}
if ($Apply -and $verified -and $workflow -ne "native" -and -not $AcceptLimitedCompatibility) {
    throw "Compatibility is $workflow. Re-run with -AcceptLimitedCompatibility after reviewing the limitations. No files were changed."
}

Write-Host "Planned targets:"
if ($verified -or $SkillPath) {
    foreach ($path in Get-ClientTargets $selectedTarget $compatibility) { Write-Host "- $path" }
} else {
    Write-Host "- BLOCKED until an explicit skill destination is supplied"
}
if (-not $Apply) { Write-Host "Analysis complete: no files changed."; return }

if ($selectedTarget -in @("kilo", "opencode")) { Install-MarkdownAgents $selectedTarget }
Install-Skills $selectedTarget $compatibility
if ($selectedTarget -eq "pi") { Install-PiPrompts }

$managerTarget = Join-Path $HOME ".ai-work-os\manage.ps1"
Backup-AndWrite $managerTarget ([System.IO.File]::ReadAllText((Join-Path $distributionRoot "scripts\manage.ps1"))) -Track
$reportPath = Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
$report = New-SetupReport $selectedTarget $selectedHost $compatibility $detectedRuntimes $verified
Backup-AndWrite $reportPath $report -Track

$ledgerPath = Join-Path $HOME ".ai-work-os\managed-files.tsv"
$ledgerLines = [System.Collections.Generic.List[string]]::new()
$ledgerLines.Add("path|installedHash|preExisting|backupPath")
foreach ($file in $managedFiles) { $ledgerLines.Add("$($file.path)|$($file.installedHash)|$([int]$file.preExisting)|$($file.backupPath)") }
Write-Utf8NoBom $ledgerPath (($ledgerLines -join "`n") + "`n")

$revision = "unknown"
if (Get-Command git -ErrorAction SilentlyContinue) {
    $candidate = (& git -C $distributionRoot rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $candidate) { $revision = $candidate.Trim() }
}
$metadata = [ordered]@{
    schemaVersion = 2
    installedAt = (Get-Date).ToUniversalTime().ToString("o")
    client = $selectedTarget
    target = $selectedTarget
    host = $selectedHost
    adapter = $adapter
    workflowCompatibility = $workflow
    routingCompatibility = $routing
    compatibilityVerified = $verified
    skillPath = if ($SkillPath) { [System.IO.Path]::GetFullPath($SkillPath) } else { "" }
    root = $distributionRoot
    sourceRevision = $revision
    report = $reportPath
    ledger = $ledgerPath
    installer = "powershell"
    managedFileCount = $managedFiles.Count
}
Write-Utf8NoBom (Join-Path $HOME ".ai-work-os\install.json") ($metadata | ConvertTo-Json -Depth 4)
Write-Host "Report: $reportPath"
