# One-time cleanup after merging Cleanup 1 over an older installation.
# Run with XIVCrossbar unloaded in ALL clients. No personal data is deleted.
param([switch]$Preview)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backup = Join-Path $root ('data/cleanup-backup/' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
function Same-File($a, $b) {
    return (Get-FileHash -LiteralPath $a -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $b -Algorithm SHA256).Hash
}
function Ensure-Parent($path) {
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path)
}
function Move-Asset($source, $relative) {
    $destination = Join-Path $root $relative
    if ($Preview) { Write-Host "Would consolidate: $source -> $destination (preserving differing art as overrides)"; return }
    if (!(Test-Path -LiteralPath $destination)) {
        Ensure-Parent $destination
        Move-Item -LiteralPath $source -Destination $destination
    } elseif (Same-File $source $destination) {
        Remove-Item -LiteralPath $source
    } else {
        # Custom legacy artwork overrides stock art without being overwritten
        # by a future complete package. The Lua resolver reads overrides first.
        $override = Join-Path $root ('images/overrides/' + $relative.Substring(7))
        if (!(Test-Path -LiteralPath $override)) {
            Ensure-Parent $override
            Move-Item -LiteralPath $source -Destination $override
        } elseif (Same-File $source $override) {
            Remove-Item -LiteralPath $source
        } else {
            # Keep the currently preferred override and retain the conflicting
            # legacy file at its original path for manual review.
            Write-Warning "Kept both different custom files: $source and $override"
        }
    }
}
$legacyRoots = @('themes', 'images/icons/iconpacks', 'images/icons/abilities', 'images/icons/spells', 'images/icons/weapons', 'images/icons/elements', 'images/icons/skillchain')
foreach ($legacy in $legacyRoots) {
    $folder = Join-Path $root $legacy
    if (!(Test-Path -LiteralPath $folder)) { continue }
    foreach ($file in @(Get-ChildItem -LiteralPath $folder -File -Recurse)) {
        $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
        if ($relative.StartsWith('themes/')) { $target = 'images/' + $relative }
        elseif ($relative.StartsWith('images/icons/iconpacks/')) { $target = $relative.Replace('images/icons/iconpacks/', 'images/icons/') }
        else { $target = $relative.Replace('images/icons/', 'images/icons/default/fallback/') }
        Move-Asset $file.FullName $target
    }
    if ($Preview) { continue }
    foreach ($dir in @(Get-ChildItem -LiteralPath $folder -Directory -Recurse | Sort-Object { $_.FullName.Length } -Descending)) {
        if (!(Get-ChildItem -LiteralPath $dir.FullName -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $dir.FullName }
    }
    if (!(Get-ChildItem -LiteralPath $folder -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $folder }
}
$manifest = Get-Content -LiteralPath (Join-Path $root 'tools/layout_legacy.json') -Raw | ConvertFrom-Json
foreach ($entry in $manifest) {
    $old = Join-Path $root $entry.old
    if (!(Test-Path -LiteralPath $old)) { continue }
    if (!(Test-Path -LiteralPath (Join-Path $root $entry.new))) { throw "Missing replacement module: $($entry.new)" }
    if ($Preview) { Write-Host "Would retire old module (backing up edits): $old"; continue }
    if ((Get-FileHash -LiteralPath $old -Algorithm SHA256).Hash -eq $entry.sha256) {
        Remove-Item -LiteralPath $old
    } else {
        $destination = Join-Path $backup $entry.old
        Ensure-Parent $destination
        Move-Item -LiteralPath $old -Destination $destination
        Write-Host "Saved modified legacy module: $destination"
    }
}
Write-Host 'Folder cleanup complete. Settings migrate separately when XIVCrossbar next loads.'
