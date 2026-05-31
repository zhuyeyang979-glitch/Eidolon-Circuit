param(
    [string]$RegistryPath = (Join-Path $PSScriptRoot "worklog_projects.json")
)

$ErrorActionPreference = "Stop"

function Get-WorklogEntry {
    param([string]$ProjectRoot, [string]$WorklogName)
    $root = [System.IO.Path]::GetFullPath($ProjectRoot)
    $path = Join-Path $root $WorklogName
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        return [pscustomobject]@{ Root = $root; Path = $path; Exists = $false; Length = 0L; LastWriteTimeUtc = [datetime]::MinValue; Hash = "" }
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{ Root = $root; Path = $path; Exists = $false; Length = 0L; LastWriteTimeUtc = [datetime]::MinValue; Hash = "" }
    }
    $item = Get-Item -LiteralPath $path
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    [pscustomobject]@{ Root = $root; Path = $path; Exists = $true; Length = $item.Length; LastWriteTimeUtc = $item.LastWriteTimeUtc; Hash = $hash }
}

if (-not (Test-Path -LiteralPath $RegistryPath -PathType Leaf)) {
    throw "Missing worklog registry: $RegistryPath"
}

$registry = Get-Content -LiteralPath $RegistryPath -Raw | ConvertFrom-Json
$worklogName = if ($registry.worklog) { [string]$registry.worklog } else { "WORKLOG_RULEBOOK.md" }
$projectRoots = @($registry.projects | ForEach-Object { [string]$_ } | Where-Object { $_ -ne "" })
if ($projectRoots.Count -eq 0) {
    throw "No project roots registered in $RegistryPath"
}

$entries = @($projectRoots | ForEach-Object { Get-WorklogEntry -ProjectRoot $_ -WorklogName $worklogName })
$existing = @($entries | Where-Object { $_.Exists })
if ($existing.Count -eq 0) {
    throw "No existing $worklogName found in registered project roots."
}

$ordered = @($existing | Sort-Object @{Expression = "LastWriteTimeUtc"; Descending = $true}, @{Expression = "Length"; Descending = $true}, @{Expression = "Hash"; Descending = $true})
$source = $ordered[0]
$latestTime = $source.LastWriteTimeUtc
$divergentLatest = @($existing | Where-Object { $_.Hash -ne $source.Hash -and $_.LastWriteTimeUtc -ge $latestTime.AddSeconds(-2) })
if ($divergentLatest.Count -gt 0) {
    $stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
    foreach ($entry in $divergentLatest) {
        $conflictPath = Join-Path $entry.Root ("WORKLOG_RULEBOOK.conflict.$stamp.md")
        Copy-Item -LiteralPath $entry.Path -Destination $conflictPath -Force
        Write-Host "CONFLICT saved $conflictPath"
    }
    throw "Worklog conflict detected. Resolve conflict copies before syncing."
}

foreach ($entry in $entries) {
    if (-not (Test-Path -LiteralPath $entry.Root -PathType Container)) {
        Write-Host "SKIP missing root $($entry.Root)"
        continue
    }
    if ($entry.Exists -and $entry.Hash -eq $source.Hash) {
        Write-Host "OK $($entry.Path) $($entry.Hash)"
        continue
    }
    Copy-Item -LiteralPath $source.Path -Destination $entry.Path -Force
    $copied = Get-Item -LiteralPath $entry.Path
    $copied.LastWriteTimeUtc = $source.LastWriteTimeUtc
    $newHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Path).Hash
    Write-Host "SYNC $($entry.Path) $newHash"
}
