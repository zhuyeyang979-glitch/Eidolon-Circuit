param(
    [ValidateSet("navigation_menu", "unit_edit", "loading_first_interaction", "all")]
    [string]$Group = "all",
    [string]$ProjectPath = "",
    [string]$Godot = "",
    [int]$TimeoutSec = 120
)

$ErrorActionPreference = "Stop"

$Runner = Join-Path $PSScriptRoot "run_godot_checked.ps1"
if (-not (Test-Path -LiteralPath $Runner)) {
    throw "Missing low-level Godot runner: $Runner"
}

$ManifestPath = Join-Path $PSScriptRoot "probe_manifest.json"
if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Missing probe manifest: $ManifestPath"
}

$Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($null -eq $Manifest.headed_gate) {
    throw "Probe manifest is missing headed_gate groups."
}

$GateGroups = [ordered]@{}
foreach ($groupName in @("navigation_menu", "unit_edit", "loading_first_interaction")) {
    $items = $Manifest.headed_gate.$groupName
    if ($null -eq $items -or $items.Count -eq 0) {
        throw "Probe manifest headed_gate.$groupName is empty or missing."
    }
    $GateGroups[$groupName] = @($items | ForEach-Object { [string]$_ })
}

function New-RunnerArgs {
    param(
        [string]$ProbeName,
        [switch]$CheckOnlyRun
    )
    $args = @("-ExecutionPolicy", "Bypass", "-File", $Runner, "-Headed", "-TimeoutSec", "$TimeoutSec")
    if (-not [string]::IsNullOrWhiteSpace($ProjectPath)) {
        $args += @("-ProjectPath", $ProjectPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($Godot)) {
        $args += @("-Godot", $Godot)
    }
    if ($CheckOnlyRun) {
        $args += "-CheckOnly"
    } else {
        $args += @("-Probe", $ProbeName)
    }
    return $args
}

function Invoke-HeadedGateItem {
    param(
        [string]$Label,
        [string[]]$Arguments
    )
    Write-Host ("[headed-gate] START {0}" -f $Label)
    $output = & powershell @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($null -ne $output -and $output.Count -gt 0) {
        $output | ForEach-Object { Write-Host $_ }
    }
    $text = ($output | Out-String)
    $badPattern = "(?m)^ERROR:|Can't load script|Failed loading resource|SCRIPT ERROR|Parse Error"
    if ($exitCode -ne 0 -or $text -match $badPattern) {
        Write-Host ("[headed-gate] FAIL {0} exit={1}" -f $Label, $exitCode)
        return $false
    }
    Write-Host ("[headed-gate] PASS {0}" -f $Label)
    return $true
}

$selectedGroups = if ($Group -eq "all") { @("navigation_menu", "unit_edit", "loading_first_interaction") } else { @($Group) }
$passed = 0
$failed = 0
$results = @()

foreach ($groupName in $selectedGroups) {
    Write-Host ("[headed-gate] GROUP {0}" -f $groupName)
    foreach ($probe in $GateGroups[$groupName]) {
        $ok = Invoke-HeadedGateItem -Label "$groupName/$probe" -Arguments (New-RunnerArgs -ProbeName $probe)
        $results += [pscustomobject]@{ Group = $groupName; Item = $probe; Passed = $ok }
        if ($ok) {
            $passed += 1
        } else {
            $failed += 1
            break
        }
    }
    if ($failed -gt 0) {
        break
    }
}

if ($failed -eq 0) {
    $ok = Invoke-HeadedGateItem -Label "headed-check-only" -Arguments (New-RunnerArgs -ProbeName "" -CheckOnlyRun)
    $results += [pscustomobject]@{ Group = "check_only"; Item = "headed-check-only"; Passed = $ok }
    if ($ok) {
        $passed += 1
    } else {
        $failed += 1
    }
}

Write-Host "[headed-gate] SUMMARY"
foreach ($result in $results) {
    Write-Host ("[headed-gate] {0} {1}/{2}" -f ($(if ($result.Passed) { "PASS" } else { "FAIL" })), $result.Group, $result.Item)
}
Write-Host ("[headed-gate] completed passed={0} failed={1}" -f $passed, $failed)

exit $(if ($failed -eq 0) { 0 } else { 1 })
