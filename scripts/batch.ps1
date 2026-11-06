<#
.SYNOPSIS  Make a Meta ad from every clip in the raw folder that doesn't have one yet.
           Extra options are passed to meta-ad.ps1 (e.g. -Mode crop, -NoLogo).
.EXAMPLE   .\scripts\batch.ps1
           .\scripts\batch.ps1 -Mode crop -MaxSecs 30
#>
param(
    [ValidateSet("blur", "crop")] [string]$Mode = "blur",
    [int]$MaxSecs = -1,
    [switch]$NoCaptions,
    [switch]$NoLogo,
    [switch]$Redo          # re-export even if a _meta file already exists
)
. "$PSScriptRoot\config.ps1"

$clips = Get-ChildItem -Path $RawDir -File | Where-Object { $_.Extension -match '^\.(mp4|mov|mkv|m4v|avi|webm)$' }
if (-not $clips) { Write-Host "No clips found in $RawDir"; exit }

$done = 0; $failed = @()
foreach ($c in $clips) {
    $target = Get-OutPath $c.FullName "_meta"
    if ((Test-Path $target) -and -not $Redo) { Write-Host "Skip (already done): $($c.Name)"; continue }
    Write-Host "`n=== $($c.Name) ===" -ForegroundColor Cyan
    try {
        & "$PSScriptRoot\meta-ad.ps1" $c.FullName -Mode $Mode -MaxSecs $MaxSecs -NoCaptions:$NoCaptions -NoLogo:$NoLogo
        $done++
    } catch {
        Write-Host "FAILED: $($c.Name) - $_" -ForegroundColor Red
        $failed += $c.Name
    }
}
Write-Host "`nFinished: $done exported, $($failed.Count) failed." -ForegroundColor Green
if ($failed) { Write-Host ("Failed: " + ($failed -join ", ")) -ForegroundColor Red }
