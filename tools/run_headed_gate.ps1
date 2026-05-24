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

$GateGroups = [ordered]@{
    navigation_menu = @(
        "navigation_service_contract_probe",
        "main_menu_navigation_probe",
        "options_menu_unification_probe",
        "page_options_router_back_probe",
        "menu_view_controller_contract_probe",
        "main_menu_table_actions_probe",
        "page_options_table_router_probe",
        "battle_runtime_options_table_probe",
        "menu_language_table_probe",
        "menu_layout_regression_probe"
    )
    unit_edit = @(
        "teamedit_probe",
        "ui_layout_probe",
        "text_overflow_probe",
        "unit_editor_fullscreen_layout_probe",
        "unit_editor_no_power_topbar_probe",
        "unit_editor_power_dock_moved_up_probe",
        "unit_editor_torso_detail_button_probe",
        "power_allocation_detail_open_close_probe",
        "power_allocation_panel_close_probe",
        "power_allocation_enter_confirms_value_probe",
        "unit_editor_training_illegal_feedback_probe"
    )
    loading_first_interaction = @(
        "startup_loading_stage_probe",
        "page_loading_transition_probe",
        "loading_navigation_contract_probe",
        "startup_deep_preload_probe",
        "teamedit_page_deep_preload_probe",
        "post_loading_first_interaction_miss_probe",
        "post_loading_real_interaction_miss_probe"
    )
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
