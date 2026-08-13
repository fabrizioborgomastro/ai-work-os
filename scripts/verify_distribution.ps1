[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$distributionRoot = Split-Path -Parent $PSScriptRoot
$required = @(
    "README.md", "ROADMAP.md", "AGENTS.md", "INSTALL.md", "install.ps1", "install.sh",
    "LICENSE", "THIRD_PARTY_NOTICES.md", "GETTING_STARTED.md", "ARCHITECTURE.md",
    "third_party/mattpocock-wayfinder/SKILL.md", "third_party/mattpocock-wayfinder/LICENSE",
    "third_party/mattpocock-wayfinder/README.md", "core/WORKFLOW.md", "core/TRACKERS.md",
    "core/ROUTING.md", "core/GATES.md", "core/BUDGETS.md", "core/PORTABILITY.md",
    "core/COMPATIBILITY.md", "core/DISPATCH.md", "adapters/compatibility.tsv",
    "templates/PROJECT.example.md", "templates/EVIDENCE_PACKAGE.md", "adapters/README.md",
    "adapters/codex/README.md", "adapters/claude/README.md", "adapters/omniroute/combos.json",
    "skills/ai-work-os/SKILL.md", "scripts/bootstrap.ps1", "scripts/bootstrap.sh",
    "scripts/manage.ps1", "scripts/manage.sh", "scripts/verify_distribution.ps1",
    "scripts/verify_distribution.sh", "scripts/test_compatibility.ps1", "scripts/test_compatibility.sh"
)
$expectedCoreAgents = @(
    "business-wayfinder", "business-engineer", "business-architect", "business-reviewer",
    "light-planner", "light-builder", "light-reviewer"
)
$expectedAdapterAgents = @($expectedCoreAgents + "ai-work-os")
$errors = [System.Collections.Generic.List[string]]::new()

foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $distributionRoot $relative) -PathType Leaf)) {
        $errors.Add("missing: $relative")
    }
}
foreach ($name in @("PROJECT.md", ".ai-work-os", ".kilo", ".wayfinder", "node_modules", "__pycache__")) {
    if (Test-Path -LiteralPath (Join-Path $distributionRoot $name)) {
        $errors.Add("distribution root contains runtime artifact: $name")
    }
}

$coreAgents = @(Get-ChildItem -LiteralPath (Join-Path $distributionRoot "core\agents") -Filter "*.md" -File | ForEach-Object BaseName | Sort-Object)
$adapterAgents = @(Get-ChildItem -LiteralPath (Join-Path $distributionRoot "adapters\markdown-agents\agents") -Filter "*.md" -File | ForEach-Object BaseName | Sort-Object)
$expectedCoreSorted = @($expectedCoreAgents | Sort-Object)
$expectedAdapterSorted = @($expectedAdapterAgents | Sort-Object)
if (($coreAgents -join "|") -ne ($expectedCoreSorted -join "|")) { $errors.Add("core agent set mismatch") }
if (($adapterAgents -join "|") -ne ($expectedAdapterSorted -join "|")) { $errors.Add("Markdown adapter agent set mismatch") }

$dispatcher = Get-Content -LiteralPath (Join-Path $distributionRoot "adapters\markdown-agents\agents\ai-work-os.md") -Raw -Encoding utf8
foreach ($requiredText in @("mode: primary", '"business-wayfinder": allow', '"business-engineer": allow', '"light-planner": allow', '"light-builder": allow')) {
    if (-not $dispatcher.Contains($requiredText)) { $errors.Add("dispatcher missing contract: $requiredText") }
}
foreach ($name in @("business-wayfinder", "business-engineer", "light-planner", "light-builder")) {
    $content = Get-Content -LiteralPath (Join-Path $distributionRoot "adapters\markdown-agents\agents\$name.md") -Raw -Encoding utf8
    if (-not $content.Contains("mode: all")) { $errors.Add("dispatchable role is not mode all: $name") }
}

$skillText = Get-Content -LiteralPath (Join-Path $distributionRoot "skills\ai-work-os\SKILL.md") -Raw -Encoding utf8
if ($skillText -notmatch '(?m)^name: ai-work-os$' -or $skillText -notmatch '(?m)^description: .*riprendi.*Code/Build') {
    $errors.Add("AI Work OS skill does not expose the universal resume trigger")
}
if ($skillText -notmatch 'apply the same dispatch table' -or $skillText -notmatch 'invoke the selected specialized role') {
    $errors.Add("AI Work OS skill does not define generic-agent dispatch")
}

$routing = Get-Content -LiteralPath (Join-Path $distributionRoot "adapters\omniroute\combos.json") -Raw -Encoding utf8 | ConvertFrom-Json
$routes = @($routing.combos.PSObject.Properties.Name | Sort-Object)
$expectedRoutes = @("business-engineering", "business-review", "light-engineering", "light-review") | Sort-Object
if (($routes -join "|") -ne ($expectedRoutes -join "|")) { $errors.Add("routing manifest does not contain exactly the four canonical routes") }

$compatibility = @(Import-Csv -LiteralPath (Join-Path $distributionRoot "adapters\compatibility.tsv") -Delimiter "|")
$knownRuntimes = @($compatibility | Where-Object { $_.kind -eq "runtime" -and $_.id -ne "generic" } | ForEach-Object id | Sort-Object)
if (($knownRuntimes -join "|") -ne ((@("claude", "codex", "kilo", "opencode", "pi") | Sort-Object) -join "|")) {
    $errors.Add("compatibility catalog runtime set mismatch")
}
foreach ($row in $compatibility | Where-Object { $_.kind -eq "runtime" -and $_.id -ne "generic" }) {
    if (-not $row.workflowLevel -or -not $row.routingLevel -or -not $row.verifiedAt -or -not $row.evidence) {
        $errors.Add("incomplete verified compatibility row: $($row.id)")
    }
}

$wayfinder = Join-Path $distributionRoot "third_party\mattpocock-wayfinder\SKILL.md"
if (Test-Path -LiteralPath $wayfinder -PathType Leaf) {
    $hash = (Get-FileHash -LiteralPath $wayfinder -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne "d33e2141f7c8bbfd137fef0213cbec465820e4680e67da5d0f0815d6742d26c2") {
        $errors.Add("vendored Wayfinder snapshot differs from the recorded upstream revision")
    }
}

foreach ($generated in Get-ChildItem -LiteralPath $distributionRoot -Recurse -Directory -Force | Where-Object Name -In @("__pycache__", "node_modules")) {
    $errors.Add("generated directory present: $($generated.FullName.Substring($distributionRoot.Length + 1))")
}
foreach ($pythonFile in Get-ChildItem -LiteralPath $distributionRoot -Recurse -File -Filter "*.py") {
    $errors.Add("Python file present in Python-free distribution: $($pythonFile.FullName.Substring($distributionRoot.Length + 1))")
}

if ($errors.Count) {
    Write-Host "AI Work OS distribution: FAIL" -ForegroundColor Red
    foreach ($error in $errors) { Write-Host "- $error" }
    exit 1
}
Write-Host "AI Work OS distribution: OK" -ForegroundColor Green
Write-Host "Root: $distributionRoot"
Write-Host "Core roles: $($expectedCoreAgents.Count)"
Write-Host "Markdown agents: $($expectedAdapterAgents.Count)"
Write-Host "Routes: $($expectedRoutes.Count)"
