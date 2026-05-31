param(
    [switch]$CheckOnly,
    [switch]$SelfTest,
    [switch]$Headed,
    [switch]$Headless,
    [string]$Probe = "",
    [string]$Script = "",
    [string]$ProjectPath = "",
    [string]$Godot = "",
    [int]$TimeoutSec = 120
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectPath {
    param([string]$InputPath)
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
    }
    return (Resolve-Path -LiteralPath $InputPath).Path
}

function Resolve-GodotPath {
    param([string]$InputPath, [string]$Root)
    if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
        return (Resolve-Path -LiteralPath $InputPath).Path
    }
    $candidate = Join-Path $Root "tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe"
    if (Test-Path -LiteralPath $candidate) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    throw "Godot console executable not found: $candidate"
}

function Stop-LingeringGodot {
    Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $path = $_.Path
            if ($path -and $path.ToLowerInvariant().EndsWith("_console.exe")) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {
        }
    }
}

function Invoke-GodotCommand {
    param(
        [string]$Exe,
        [string]$Root,
        [string]$Arguments,
        [int]$LimitSec,
        [string]$Label
    )
    $stdout = Join-Path $env:TEMP ("eidolon_godot_{0}_out.log" -f ([guid]::NewGuid().ToString("N")))
    $stderr = Join-Path $env:TEMP ("eidolon_godot_{0}_err.log" -f ([guid]::NewGuid().ToString("N")))
    $proc = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory $Root -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    if (-not $proc.WaitForExit([Math]::Max(1, $LimitSec) * 1000)) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        } catch {
        }
        Stop-LingeringGodot
        $outText = if (Test-Path -LiteralPath $stdout) { Get-Content -LiteralPath $stdout -Raw } else { "" }
        $errText = if (Test-Path -LiteralPath $stderr) { Get-Content -LiteralPath $stderr -Raw } else { "" }
        return [pscustomobject]@{ Label = $Label; ExitCode = -999; TimedOut = $true; Stdout = $outText; Stderr = $errText }
    }
    $proc.Refresh()
    $exitCode = $proc.ExitCode
    if ($null -eq $exitCode) {
        $exitCode = 0
    }
    $out = if (Test-Path -LiteralPath $stdout) { Get-Content -LiteralPath $stdout -Raw } else { "" }
    $err = if (Test-Path -LiteralPath $stderr) { Get-Content -LiteralPath $stderr -Raw } else { "" }
    return [pscustomobject]@{ Label = $Label; ExitCode = $exitCode; TimedOut = $false; Stdout = $out; Stderr = $err }
}

function Write-RunResult {
    param($Result)
    Write-Host ("[{0}] exit={1} timeout={2}" -f $Result.Label, $Result.ExitCode, $Result.TimedOut)
    if (-not [string]::IsNullOrWhiteSpace($Result.Stdout)) {
        Write-Host $Result.Stdout.Trim()
    }
    if (-not [string]::IsNullOrWhiteSpace($Result.Stderr)) {
        Write-Host $Result.Stderr.Trim()
    }
}

function Test-RunFailed {
    param($Result)
    if ($Result.ExitCode -ne 0 -or $Result.TimedOut) {
        return $true
    }
    $combined = "{0}`n{1}" -f $Result.Stdout, $Result.Stderr
    return ($combined -match "(?m)^ERROR:|Can't load script|Failed loading resource|SCRIPT ERROR|Parse Error")
}

$RootPath = Resolve-ProjectPath $ProjectPath
$GodotPath = Resolve-GodotPath $Godot $RootPath

if ($Headed -and $Headless) {
    throw "Use either -Headed or -Headless, not both. Headed is the project default."
}

if ($SelfTest) {
    if ($RootPath -notmatch "\s") {
        throw "Self-test expects a project path with a space; current path is '$RootPath'."
    }
    $quotedArgs = "--headless --path `"$RootPath`" --check-only --quit-after 1"
    if ($quotedArgs -notlike "*`"$RootPath`"*") {
        throw "Self-test failed to quote project path."
    }
    Stop-LingeringGodot
    $result = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $quotedArgs -LimitSec ([Math]::Min($TimeoutSec, 30)) -Label "selftest-check-only"
    Write-RunResult $result
    if (($result.Stdout + $result.Stderr) -match 'Invalid project path specified: "E:\\New"') {
        throw "Self-test detected split project path. Quoting is broken."
    }
    if ($result.ExitCode -ne 0) {
        throw "Self-test check-only failed with exit code $($result.ExitCode)."
    }
    $lingeringConsole = Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.ToLowerInvariant().EndsWith("_console.exe") }
    if ($lingeringConsole) {
        throw "Self-test left lingering console Godot processes."
    }
    Write-Host "SELFTEST OK: quoted project path, check-only, and process cleanup verified."
    exit 0
}

if (-not [string]::IsNullOrWhiteSpace($Probe) -and [string]::IsNullOrWhiteSpace($Script)) {
    $Script = $Probe
}

if (-not $CheckOnly -and [string]::IsNullOrWhiteSpace($Script)) {
    $CheckOnly = $true
}

if ($CheckOnly) {
    if (-not $Headless) {
        $headedArgs = "--path `"$RootPath`" --check-only --quit-after 1"
        $headedResult = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $headedArgs -LimitSec $TimeoutSec -Label "headed-check-only"
        Write-RunResult $headedResult
        if (-not (Test-RunFailed $headedResult)) {
            exit 0
        }
        exit 1
    }
    $args = "--headless --path `"$RootPath`" --check-only --quit-after 1"
    $first = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $args -LimitSec $TimeoutSec -Label "headless-check-only"
    Write-RunResult $first
    if (-not (Test-RunFailed $first)) {
        exit 0
    }
    Stop-LingeringGodot
    $second = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $args -LimitSec $TimeoutSec -Label "headless-check-only-retry"
    Write-RunResult $second
    if (-not (Test-RunFailed $second)) {
        exit 0
    }
    $headedArgs = "--path `"$RootPath`" --check-only --quit-after 1"
    $headed = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $headedArgs -LimitSec $TimeoutSec -Label "headed-check-only"
    Write-RunResult $headed
    if (-not (Test-RunFailed $headed)) {
        exit 0
    }
    $fallback = "res://tools/check_only_fallback_probe.gd"
    $fallbackArgs = "--headless --path `"$RootPath`" --script $fallback"
    $fallbackResult = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $fallbackArgs -LimitSec ([Math]::Min($TimeoutSec, 45)) -Label "fallback-script-load"
    Write-RunResult $fallbackResult
    exit $fallbackResult.ExitCode
}

if (-not [string]::IsNullOrWhiteSpace($Script)) {
    $scriptPath = $Script
    if (-not $scriptPath.StartsWith("res://")) {
        $scriptPath = $scriptPath -replace "\\", "/"
        if ($scriptPath.StartsWith("tools/")) {
            $scriptPath = $scriptPath.Substring(6)
        }
        if (-not $scriptPath.EndsWith(".gd")) {
            $scriptPath = "$scriptPath.gd"
        }
        $scriptPath = "res://tools/$scriptPath"
    } elseif (-not $scriptPath.EndsWith(".gd")) {
        $scriptPath = "$scriptPath.gd"
    }
    $scriptArgs = if (-not $Headless) { "--path `"$RootPath`" --script $scriptPath" } else { "--headless --path `"$RootPath`" --script $scriptPath" }
    $scriptLabel = if (-not $Headless) { "headed-script-$scriptPath" } else { "headless-script-$scriptPath" }
    $scriptResult = Invoke-GodotCommand -Exe $GodotPath -Root $RootPath -Arguments $scriptArgs -LimitSec $TimeoutSec -Label $scriptLabel
    Write-RunResult $scriptResult
    if (Test-RunFailed $scriptResult) {
        exit 1
    }
    exit 0
}
