[CmdletBinding()]
param(
    [ValidateSet("auto", "kilo", "opencode", "pi", "codex", "claude", "generic")]
    [string]$Client = "auto",

    [switch]$Apply
)

$ErrorActionPreference = "Stop"
$distributionRoot = Split-Path -Parent $PSScriptRoot
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
$roleNames = @(
    "business-wayfinder",
    "business-engineer",
    "business-architect",
    "business-reviewer",
    "light-planner",
    "light-builder",
    "light-reviewer"
)
$routeNames = @(
    "business-engineering",
    "business-review",
    "light-engineering",
    "light-review"
)
$clientCommands = [ordered]@{
    kilo = "kilo"
    opencode = "opencode"
    pi = "pi"
    codex = "codex"
    claude = "claude"
}

function Get-DetectedClients {
    $found = @()
    foreach ($entry in $clientCommands.GetEnumerator()) {
        if (Get-Command $entry.Value -ErrorAction SilentlyContinue) {
            $found += $entry.Key
        }
    }
    return @($found)
}

function Resolve-SelectedClient([string]$Requested, [string[]]$Detected) {
    if ($Requested -ne "auto") {
        return $Requested
    }
    if ($Detected.Count -eq 1) {
        return $Detected[0]
    }
    $detectedText = if ($Detected.Count) { $Detected -join ", " } else { "none" }
    throw "Automatic client selection requires exactly one supported client on PATH; detected: $detectedText. Re-run with an explicit -Client."
}

function Get-SkillBase([string]$SelectedClient) {
    if ($SelectedClient -eq "kilo") {
        return Join-Path $HOME ".kilo\skills"
    }
    if ($SelectedClient -eq "opencode") {
        return Join-Path $HOME ".config\opencode\skills"
    }
    if ($SelectedClient -eq "pi") {
        return Join-Path $HOME ".pi\agent\skills"
    }
    if ($SelectedClient -in @("codex", "claude")) {
        return Join-Path $HOME ".$SelectedClient\skills"
    }
    return Join-Path $HOME ".agents\skills"
}

function Get-ClientTargets([string]$SelectedClient) {
    $skillBase = Get-SkillBase $SelectedClient
    $targets = @()
    if ($SelectedClient -eq "kilo") {
        $targets += Join-Path $HOME ".config\kilo\agents"
    } elseif ($SelectedClient -eq "opencode") {
        $targets += Join-Path $HOME ".config\opencode\agents"
    }
    $targets += Join-Path $skillBase "ai-work-os"
    $targets += Join-Path $skillBase "wayfinder"
    if ($SelectedClient -eq "pi") {
        $targets += Join-Path $HOME ".pi\agent\prompts"
    }
    $targets += Join-Path $HOME ".ai-work-os\manage.ps1"
    $targets += Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    $targets += Join-Path $HOME ".ai-work-os\install.json"
    $targets += Join-Path $HOME ".ai-work-os\managed-files.tsv"
    return @($targets)
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Register-ManagedFile([string]$Path, [bool]$PreExisting, [string]$BackupPath) {
    if ($Path.Contains("|") -or $Path.Contains("`n") -or $Path.Contains("`r")) {
        throw "Managed paths cannot contain pipes or newlines: $Path"
    }
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
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $existing = [System.IO.File]::ReadAllText($Path)
        if ($existing -ne $Content) {
            $backupPath = "$Path.backup-$stamp"
            Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        }
    }
    Write-Utf8NoBom $Path $Content
    if ($Track) {
        Register-ManagedFile $Path $preExisting $backupPath
    }
}

function Install-Skills([string]$SelectedClient) {
    $skillBase = Get-SkillBase $SelectedClient
    $portableRoot = $distributionRoot.Replace("\", "/")
    $skillSource = Join-Path $distributionRoot "skills\ai-work-os\SKILL.md"
    $skillContent = [System.IO.File]::ReadAllText($skillSource).Replace("{{AI_WORK_OS_HOME}}", $portableRoot)
    Backup-AndWrite (Join-Path $skillBase "ai-work-os\SKILL.md") $skillContent -Track

    $wayfinderSource = Join-Path $distributionRoot "third_party\mattpocock-wayfinder"
    foreach ($name in @("SKILL.md", "LICENSE", "README.md")) {
        $content = [System.IO.File]::ReadAllText((Join-Path $wayfinderSource $name))
        Backup-AndWrite (Join-Path $skillBase "wayfinder\$name") $content -Track
    }
}

function Install-MarkdownAgents([string]$SelectedClient) {
    if ($SelectedClient -eq "kilo") {
        $target = Join-Path $HOME ".config\kilo\agents"
    } else {
        $target = Join-Path $HOME ".config\opencode\agents"
    }
    $source = Join-Path $distributionRoot "adapters\markdown-agents\agents"
    $portableRoot = $distributionRoot.Replace("\", "/")
    foreach ($file in Get-ChildItem -LiteralPath $source -Filter "*.md" -File | Sort-Object Name) {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $content = $content.Replace('`core/', ('`' + $portableRoot + '/core/'))
        $content = $content.Replace('`templates/', ('`' + $portableRoot + '/templates/'))
        Backup-AndWrite (Join-Path $target $file.Name) $content -Track
    }
}

function Install-PiPrompts {
    $target = Join-Path $HOME ".pi\agent\prompts"
    $portableRoot = $distributionRoot.Replace("\", "/")
    $policies = "WORKFLOW.md, TRACKERS.md, ROUTING.md, GATES.md and BUDGETS.md"
    foreach ($role in $roleNames) {
        $content = @"
Activate the AI Work OS ``$role`` role for the project in the current working directory.

Read and follow ``$portableRoot/core/agents/$role.md`` and the shared policies under ``$portableRoot/core/`` ($policies). Treat ``$portableRoot`` as read-only. Persist all operational artifacts and handoffs in the actual project.
"@
        Backup-AndWrite (Join-Path $target "ai-$role.md") $content -Track
    }
}

function Get-ClientConfigText([string]$SelectedClient) {
    $candidates = @()
    if ($SelectedClient -eq "kilo") {
        $candidates = @(Join-Path $HOME ".config\kilo\kilo.jsonc")
    } elseif ($SelectedClient -eq "opencode") {
        $candidates = @(
            (Join-Path $HOME ".config\opencode\opencode.json"),
            (Join-Path $HOME ".config\opencode\opencode.jsonc")
        )
    } elseif ($SelectedClient -eq "pi") {
        $candidates = @(Join-Path $HOME ".pi\agent\models.json")
    }
    $chunks = @()
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $chunks += [System.IO.File]::ReadAllText($path)
        }
    }
    return $chunks -join "`n"
}

function New-SetupReport([string]$SelectedClient, [string[]]$Detected, [bool]$Applied) {
    $configText = Get-ClientConfigText $SelectedClient
    $missingRoutes = @($routeNames | Where-Object { -not $configText.Contains($_) })
    $status = if ($Applied) { "APPLIED" } else { "DRY RUN - no files changed" }
    $detectedText = if ($Detected.Count) { $Detected -join ", " } else { "none" }
    $targetsText = (Get-ClientTargets $SelectedClient | ForEach-Object { "- ``$_``" }) -join "`n"
    $missingText = if ($missingRoutes.Count) {
        ($missingRoutes | ForEach-Object { "- ``$_``" }) -join "`n"
    } else {
        "- none detected"
    }
    return @"
# AI Work OS setup report

- Status: **$status**
- Client selected: ``$SelectedClient``
- Clients detected on PATH: $detectedText
- Installation scope: only the selected client (``$SelectedClient``)
- Canonical core: ``$distributionRoot``

## Installation targets

$targetsText

## Route names not found in the inspected client configuration

$missingText

This is a textual presence check, not proof that routes, providers, privacy policies or fallbacks work. Configure and verify all four routes according to ``$distributionRoot\core\ROUTING.md``. A route may live in an external router and therefore not appear in the client config.

## Manual checklist

1. Configure model/provider credentials using the client's secure credential flow.
2. For Business, verify no free endpoints, ZDR/no-training, allowlist and spending cap.
3. For Light, set the project spending cap and never provide sensitive material to free endpoints.
4. Reload the selected client and confirm the installed roles or skills are visible.
5. If GitHub Issues is selected later, approve an official integration and authentication method.
6. Open a synthetic project and test planning -> handoff -> build without paid calls where possible.

## Lifecycle commands

Run these commands from any directory in PowerShell:

- ``& "$HOME\.ai-work-os\manage.ps1" -Status``
- ``& "$HOME\.ai-work-os\manage.ps1" -Doctor``
- ``& "$HOME\.ai-work-os\manage.ps1" -Update -DryRun``
- ``& "$HOME\.ai-work-os\manage.ps1" -Uninstall -DryRun``

## Client capability note

- Kilo and OpenCode receive seven native Markdown agent definitions plus skills.
- Pi receives seven role prompts plus skills.
- Codex and Claude Code receive skills only; their native subagent and routing configuration is intentionally not changed without explicit approval.
- Multi-provider combo behavior is router/client-specific and is never assumed from skill installation alone.

## Bundled third-party component

- Wayfinder by Matt Pocock, revision ``84fdeffd12f2ee307994d1eb6feb48173b6e0502``.
- License: MIT; the copyright notice and license are installed beside the skill.
- See ``$distributionRoot\THIRD_PARTY_NOTICES.md`` for provenance and attribution.

## First use

- Business: start with ``business-wayfinder`` unless decisions are already mature.
- Light: start with ``light-planner`` unless the task is already small and fully specified.
"@
}

$detectedClients = @(Get-DetectedClients)
$selectedClient = Resolve-SelectedClient $Client $detectedClients
$detectedDisplay = if ($detectedClients.Count) { $detectedClients -join ", " } else { "none" }

Write-Host "AI Work OS: $distributionRoot"
Write-Host "Requested client: $Client"
Write-Host "Detected clients: $detectedDisplay (informational only)"
Write-Host "Selected adapter: $selectedClient"
Write-Host "Installation scope: only $selectedClient"
Write-Host "Planned targets:"
foreach ($target in Get-ClientTargets $selectedClient) {
    Write-Host "- $target"
}

if ($Apply) {
    if ($selectedClient -in @("kilo", "opencode")) {
        Install-MarkdownAgents $selectedClient
        Install-Skills $selectedClient
    } elseif ($selectedClient -eq "pi") {
        Install-Skills $selectedClient
        Install-PiPrompts
    } else {
        Install-Skills $selectedClient
    }

    $managerSource = Join-Path $distributionRoot "scripts\manage.ps1"
    $managerTarget = Join-Path $HOME ".ai-work-os\manage.ps1"
    Backup-AndWrite $managerTarget ([System.IO.File]::ReadAllText($managerSource)) -Track
}

$report = New-SetupReport $selectedClient $detectedClients $Apply.IsPresent
if ($Apply) {
    $reportPath = Join-Path $HOME ".ai-work-os\SETUP-REPORT.md"
    Backup-AndWrite $reportPath $report -Track
    $ledgerPath = Join-Path $HOME ".ai-work-os\managed-files.tsv"
    $ledgerLines = [System.Collections.Generic.List[string]]::new()
    $ledgerLines.Add("path|installedHash|preExisting|backupPath")
    foreach ($file in $managedFiles) {
        $ledgerLines.Add("$($file.path)|$($file.installedHash)|$([int]$file.preExisting)|$($file.backupPath)")
    }
    Write-Utf8NoBom $ledgerPath (($ledgerLines -join "`n") + "`n")
    $revision = "unknown"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $candidate = (& git -C $distributionRoot rev-parse HEAD 2>$null)
        if ($LASTEXITCODE -eq 0 -and $candidate) { $revision = $candidate.Trim() }
    }
    $metadata = [ordered]@{
        schemaVersion = 1
        installedAt = (Get-Date).ToUniversalTime().ToString("o")
        client = $selectedClient
        root = $distributionRoot
        sourceRevision = $revision
        report = $reportPath
        ledger = $ledgerPath
        installer = "powershell"
        managedFileCount = $managedFiles.Count
        thirdParty = [ordered]@{
            wayfinder = [ordered]@{
                revision = "84fdeffd12f2ee307994d1eb6feb48173b6e0502"
                license = "MIT"
            }
        }
    }
    Write-Utf8NoBom (Join-Path $HOME ".ai-work-os\install.json") ($metadata | ConvertTo-Json -Depth 5)
    Write-Host "Report: $reportPath"
} else {
    Write-Host ""
    Write-Host $report
}
