[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$bootstrap = Join-Path $PSScriptRoot "bootstrap.ps1"
$errors = [System.Collections.Generic.List[string]]::new()

function Capture-Analysis([hashtable]$Arguments) {
    return (& $bootstrap @Arguments *>&1 | Out-String)
}

$cursorClaude = Capture-Analysis @{ Target = "claude"; HostApp = "cursor" }
if ($cursorClaude -notmatch "Host/editor: cursor" -or $cursorClaude -notmatch "Workflow compatibility: skill-only") {
    $errors.Add("Cursor -> Claude was not classified as skill-only")
}
if ($cursorClaude -match [regex]::Escape("$HOME\.config\kilo")) {
    $errors.Add("Cursor -> Claude planned a Kilo target")
}

$antigravityKilo = Capture-Analysis @{ Target = "kilo"; HostApp = "antigravity" }
if ($antigravityKilo -notmatch "Host/editor: antigravity" -or $antigravityKilo -notmatch "Routing compatibility: native-combo") {
    $errors.Add("Antigravity -> Kilo classification mismatch")
}

$vscodeOpenCode = Capture-Analysis @{ Target = "opencode"; HostApp = "vscode" }
if ($vscodeOpenCode -notmatch "Multiprovider routing: NOT CONFIGURED" -or $vscodeOpenCode -notmatch "OmniRoute") {
    $errors.Add("VS Code -> OpenCode did not explain the routing requirement and OmniRoute option")
}

$unknown = Capture-Analysis @{ Target = "unknown-test-runtime" }
if ($unknown -notmatch "Catalog status: UNVERIFIED" -or $unknown -notmatch "BLOCKED until an explicit skill destination") {
    $errors.Add("Unknown runtime audit did not block the implicit destination")
}

try {
    & $bootstrap -Target claude -HostApp cursor -Apply *>$null
    $errors.Add("Limited compatibility apply did not require acknowledgement")
} catch {
    if ($_.Exception.Message -notmatch "AcceptLimitedCompatibility") { $errors.Add("Unexpected limited compatibility error: $($_.Exception.Message)") }
}

try {
    & $bootstrap -Target unknown-test-runtime -Apply *>$null
    $errors.Add("Unknown runtime apply did not require an explicit skill path")
} catch {
    if ($_.Exception.Message -notmatch "SkillPath") { $errors.Add("Unexpected unknown-runtime error: $($_.Exception.Message)") }
}

if ($errors.Count) {
    Write-Host "Compatibility tests: FAIL" -ForegroundColor Red
    foreach ($error in $errors) { Write-Host "- $error" }
    exit 1
}
Write-Host "Compatibility tests: OK" -ForegroundColor Green
Write-Host "Cases: Cursor/Claude, VS Code/OpenCode, Antigravity/Kilo, unknown runtime, acknowledgement gates"
