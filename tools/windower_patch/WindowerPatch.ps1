#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Package,
    [string]$WindowerRoot = $PSScriptRoot,
    [switch]$DeletePackage,
    [switch]$LibraryOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-FileDigest([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Get-SafeRelative([string]$Name) {
    $relative = $Name.Replace('\','/')
    if (!$relative -or $relative.StartsWith('/') -or $relative -match '[<>:"|?*\x00-\x1f]') { throw "Invalid package path: $Name" }
    foreach ($part in $relative.Split('/')) {
        if (!$part -or $part -eq '.' -or $part -eq '..' -or $part -match '[ .]$' -or $part -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
            throw "Invalid package path: $Name"
        }
    }
    return $relative
}
function Assert-CodePath([string]$Relative) {
    $null = Get-SafeRelative $Relative
    if ($Relative -match '^(data|images)(/|$)' -or ($Relative -notmatch '\.(lua|ahk|md)$' -and $Relative -ne 'PATCH-INFO.txt')) {
        throw "This installer accepts code/docs only; unsupported file: $Relative"
    }
}
function Assert-NoLink([string]$Path, [string]$Root) {
    $current = [IO.Path]::GetFullPath($Path)
    $boundary = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (!$current.StartsWith($boundary + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Destination escapes Windower root.' }
    while ($current -and $current -ne $boundary) {
        if (Test-Path -LiteralPath $current) {
            if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked install path unsupported: $current" }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}
function Expand-CheckedZip([string]$Zip, [string]$Stage) {
    $archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        $seen = @{}; $total = [long]0
        if ($archive.Entries.Count -gt 10000) { throw 'Too many ZIP entries.' }
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName.Replace('\','/')
            if ($name.EndsWith('/')) { $null = Get-SafeRelative $name.TrimEnd('/'); continue }
            $name = Get-SafeRelative $name
            if ($seen.ContainsKey($name)) { throw "Duplicate ZIP path: $name" }
            $seen[$name] = $true
            if ((($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'ZIP links are unsupported.' }
            $total += $entry.Length
            if ($entry.Length -gt 64MB -or $total -gt 256MB) { throw 'Code package exceeds size limit.' }
            $destination = Join-Path $Stage $name
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$destination,$false)
        }
    } finally { $archive.Dispose() }
}
function Get-XivPayload([string]$Stage) {
    $addon = Join-Path $Stage 'xivcrossbar'
    if (!(Test-Path -LiteralPath (Join-Path $addon 'xivcrossbar.lua') -PathType Leaf)) { throw 'Package must contain xivcrossbar/xivcrossbar.lua.' }
    $manifestPath = Join-Path $Stage 'windower-patch.json'
    $files = @(); $commit = 'legacy package'
    if (Test-Path -LiteralPath $manifestPath) {
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($manifest.schema -ne 1 -or $manifest.addon -ne 'xivcrossbar') { throw 'Unsupported patch manifest.' }
        $seen = @{}
        foreach ($file in $manifest.files) {
            $relative = Get-SafeRelative ([string]$file.path); Assert-CodePath $relative
            if ($seen.ContainsKey($relative)) { throw 'Duplicate manifest path.' }; $seen[$relative] = $true
            $source = Join-Path $addon $relative
            if (!(Test-Path -LiteralPath $source -PathType Leaf) -or (Get-FileDigest $source) -ne $file.sha256) { throw "Package checksum mismatch: $relative" }
            $files += [pscustomobject]@{Relative=$relative; Source=$source; SHA256=(Get-FileDigest $source)}
        }
        $actual = @(Get-ChildItem -LiteralPath $addon -File -Recurse)
        if ($actual.Count -ne $files.Count) { throw 'Package has files outside its manifest.' }
        $commit = [string]$manifest.source_commit
    } else {
        $info = Join-Path $addon 'PATCH-INFO.txt'
        if (!(Test-Path -LiteralPath $info) -or (Get-Content -LiteralPath $info -Raw) -notmatch '(?i)XIVcrossbar') { throw 'Unrecognised ZIP. Select a cumulative XIVcrossbar code patch.' }
        foreach ($file in Get-ChildItem -LiteralPath $addon -File -Recurse) {
            $relative = $file.FullName.Substring($addon.Length + 1).Replace('\','/'); Assert-CodePath $relative
            $files += [pscustomobject]@{Relative=$relative; Source=$file.FullName; SHA256=(Get-FileDigest $file.FullName)}
        }
    }
    if (!$files.Count) { throw 'Empty package.' }
    $source = Get-Content -LiteralPath (Join-Path $addon 'xivcrossbar.lua') -Raw
    if ($source -notmatch "_addon\.version\s*=\s*'([^']+)'") { throw 'Cannot read package version.' }
    $version = $Matches[1]
    if ((Test-Path -LiteralPath $manifestPath) -and $manifest.version -ne $version) { throw 'Manifest/source version mismatch.' }
    return [pscustomobject]@{Files=$files; Version=$version; Commit=$commit}
}
function Get-XivOwners([string]$AddonRoot) {
    $directory = Join-Path $AddonRoot 'data/controller-clients'
    if (!(Test-Path -LiteralPath $directory)) { return }
    foreach ($record in Get-ChildItem -LiteralPath $directory -Filter '*.ini' -File) {
        try {
            $handle = [IO.File]::Open($record.FullName + '.owner',[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
            $handle.Dispose()
        } catch {
            $code = $_.Exception.GetBaseException().HResult -band 65535
            if ($code -notin 2,3) { [pscustomobject]@{Record=$record.Name; Code=$code} }
        }
    }
}
function Write-InstallerRequest([string]$AddonRoot,[string]$Id) {
    $path = Join-Path $AddonRoot 'data/installer-request.ini'
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
    $expires = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 120
    [IO.File]::WriteAllText($path + '.tmp',"[Installer]`nprotocol=1`nid=$Id`naction=unload`nexpires=$expires`nEND`n",[Text.Encoding]::ASCII)
    Move-Item -LiteralPath ($path + '.tmp') -Destination $path -Force
}
function Wait-XivUnloaded([string]$AddonRoot,[int]$Seconds=60) {
    $limit = [DateTime]::UtcNow.AddSeconds($Seconds)
    while (@(Get-XivOwners $AddonRoot).Count) {
        if ([DateTime]::UtcNow -ge $limit) { throw 'XB still has owners. Close its editing menus or manually unload it on all clients, then retry. No code installed.' }
        Write-Progress -Activity 'Waiting for XIVcrossbar to unload' -Status 'Close XB editing menus. First install: unload XB manually on every client.'
        Start-Sleep -Milliseconds 250
    }
    Write-Progress -Activity 'Waiting for XIVcrossbar to unload' -Completed
}
function Read-InstallAcks([string]$AddonRoot,[string]$Id) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $AddonRoot 'data') -Filter "installer-ack-$Id-*.ini" -ErrorAction SilentlyContinue) {
        try {
            if ($file.Length -gt 2048) { continue }
            $ack = ConvertFrom-StringData ([IO.File]::ReadAllText($file.FullName).Replace('[InstallerAck]',''))
            if ($ack.protocol -eq '1' -and $ack.id -eq $Id -and $ack.state -in 'busy','unloading') {
                [pscustomobject]@{Session=$ack.session; Character=$ack.character; State=$ack.state; Version=$ack.version}
            }
        } catch { Write-Warning "Could not read installer acknowledgement: $($file.Name)" }
    }
}
function Stop-XivWrapper([string]$AddonRoot) {
    $statusPath = Join-Path $AddonRoot 'data/controller-status.ini'
    if (!(Test-Path -LiteralPath $statusPath)) { return }
    $status = ConvertFrom-StringData (Get-Content -LiteralPath $statusPath -Raw).Replace('[Controller]','').Replace('\','\\')
    $wrapperPid = 0
    if ($status.ContainsKey('pid')) { $null = [int]::TryParse([string]$status.pid,[ref]$wrapperPid) }
    if (!$wrapperPid) {
        if ($status.ContainsKey('state') -and $status.state -eq 'stopped') { return }
        throw 'Wrapper status has no valid PID. Stop the XIVcrossbar wrapper manually, then retry.'
    }
    if (!(Get-Process -Id $wrapperPid -ErrorAction SilentlyContinue)) { return }
    $stopPath = Join-Path $AddonRoot 'data/input-stop.request'
    $stamp = [string][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    [IO.File]::WriteAllText($stopPath,$stamp)
    try {
        $limit = [DateTime]::UtcNow.AddSeconds(10)
        while (Get-Process -Id $wrapperPid -ErrorAction SilentlyContinue) {
            if ([DateTime]::UtcNow -ge $limit) { throw 'Wrapper did not stop. Stop the XIVcrossbar wrapper manually, then retry. No code installed.' }
            Start-Sleep -Milliseconds 200
        }
    } finally {
        if ((Test-Path -LiteralPath $stopPath) -and [IO.File]::ReadAllText($stopPath) -eq $stamp) { Remove-Item -LiteralPath $stopPath -Force }
    }
}
function Install-XivPayload($Payload,[string]$AddonRoot,[string]$BackupRoot,[scriptblock]$BeforeWrite={}) {
    $null = [IO.Directory]::CreateDirectory($BackupRoot)
    $journal = @(); $changed = @()
    foreach ($file in $Payload.Files) {
        Assert-CodePath $file.Relative
        $destination = Join-Path $AddonRoot $file.Relative
        Assert-NoLink $destination ([IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($AddonRoot)))
        if ((Test-Path -LiteralPath $destination) -and !(Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Destination is not a file: $destination" }
        if ((Get-FileDigest $file.Source) -ne $file.SHA256) { throw 'Staged file changed before installation.' }
        $existed = Test-Path -LiteralPath $destination -PathType Leaf
        if ($existed -and (Get-FileDigest $destination) -eq $file.SHA256) { continue }
        $backup = Join-Path $BackupRoot ('files/' + $file.Relative)
        if ($existed) {
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($backup))
            [IO.File]::Copy($destination,$backup,$false)
        }
        $journal += [pscustomobject]@{Relative=$file.Relative; Destination=$destination; Backup=$backup; Existed=$existed; SHA256=$file.SHA256}
    }
    $journal | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $BackupRoot 'files.json') -Encoding UTF8
    try {
        foreach ($item in $journal) {
            if (@(Get-XivOwners $AddonRoot).Count) { throw 'A client loaded XB during installation.' }
            & $BeforeWrite $item
            $file = $Payload.Files | Where-Object {$_.Relative -eq $item.Relative} | Select-Object -First 1
            $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($item.Destination))
            $temporary = $item.Destination + '.windowerpatch.tmp'
            $changed += $item
            [IO.File]::Copy($file.Source,$temporary,$true)
            if ($item.Existed) { [IO.File]::Replace($temporary,$item.Destination,[NullString]::Value) }
            else { [IO.File]::Move($temporary,$item.Destination) }
            if ((Get-FileDigest $item.Destination) -ne $item.SHA256) { throw "Installed checksum mismatch: $($item.Relative)" }
        }
        foreach ($file in $Payload.Files) {
            if ((Get-FileDigest (Join-Path $AddonRoot $file.Relative)) -ne $file.SHA256) { throw "Final verification failed: $($file.Relative)" }
        }
    } catch {
        $original = $_; $rollbackErrors = @()
        foreach ($item in @($changed | Sort-Object -Property Relative -Descending)) {
            try {
                if ($item.Existed) { [IO.File]::Copy($item.Backup,$item.Destination,$true) }
                elseif (Test-Path -LiteralPath $item.Destination) { Remove-Item -LiteralPath $item.Destination -Force }
                if (Test-Path -LiteralPath ($item.Destination + '.windowerpatch.tmp')) { Remove-Item -LiteralPath ($item.Destination + '.windowerpatch.tmp') -Force }
            } catch { $rollbackErrors += [string]$_ }
        }
        if ($rollbackErrors.Count) { throw "Installation failed: $original. Rollback incomplete: $($rollbackErrors -join '; '). Backup: $BackupRoot" }
        throw "Installation failed; changed files restored. $original"
    }
    return @($journal).Count
}
function Select-PatchZip {
    Add-Type -AssemblyName System.Windows.Forms
    $picker = New-Object Windows.Forms.OpenFileDialog
    try {
        $picker.Title = 'Select the downloaded XIVcrossbar cumulative patch'
        $picker.Filter = 'ZIP patch (*.zip)|*.zip'
        $picker.InitialDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        if ($picker.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'No package selected.' }
        return $picker.FileName
    } finally { $picker.Dispose() }
}

if ($LibraryOnly) { return }
$lock = $null; $stage = $null; $addonRoot = $null; $id = [Guid]::NewGuid().ToString('N')
$report = [ordered]@{schema=1; id=$id; started=[DateTime]::UtcNow.ToString('o'); state='preparing'; reload='manual'}
$requestWritten = $false; $exitCode = 0
try {
    $WindowerRoot = [IO.Path]::GetFullPath($WindowerRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (!(Test-Path -LiteralPath (Join-Path $WindowerRoot 'addons') -PathType Container)) { throw 'Place launcher beside Windower.exe, in the root containing addons.' }
    $support = Join-Path $WindowerRoot 'WindowerPatchSupport'
    $null = [IO.Directory]::CreateDirectory($support)
    $lock = [IO.File]::Open((Join-Path $support 'install.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $run = Join-Path $support ('runs/' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + $id.Substring(0,8))
    $null = [IO.Directory]::CreateDirectory($run); $reportPath = Join-Path $run 'install-report.json'
    $addonRoot = Join-Path $WindowerRoot 'addons/xivcrossbar'
    $bootstrap = Join-Path $support 'bootstrap'
    $bootstrapCore = Join-Path $bootstrap 'xivcrossbar/xivcrossbar.lua'
    $installedCore = Join-Path $addonRoot 'xivcrossbar.lua'
    if (!(Test-Path -LiteralPath $installedCore -PathType Leaf)) { throw 'An existing XIVcrossbar installation is required. This kit contains a cumulative update, not the full addon/artwork.' }
    $bootstrapReceipt = Join-Path $support 'bootstrap-completed.json'
    $bootstrapInstall = !$Package -and (Test-Path -LiteralPath $bootstrapCore) -and !(Test-Path -LiteralPath $bootstrapReceipt)
    if ($bootstrapInstall) {
        $stage = $bootstrap; $report.package = 'bundled bootstrap'
    } else {
        if (!$Package) { $Package = Select-PatchZip }
        $Package = (Resolve-Path -LiteralPath $Package).Path
        if ([IO.Path]::GetExtension($Package) -ne '.zip') { throw 'Choose a ZIP patch.' }
        $stage = Join-Path $run 'stage'; $null = [IO.Directory]::CreateDirectory($stage)
        Expand-CheckedZip $Package $stage
        $report.package = $Package; $report.package_sha256 = Get-FileDigest $Package
    }
    $payload = Get-XivPayload $stage
    $report.version = $payload.Version; $report.source_commit = $payload.Commit
    Write-Host "XIVcrossbar $($payload.Version): $($payload.Files.Count) code/docs files. Your bindings and artwork stay in place."
    Write-Host 'Reload clients yourself after installation. Close XB editing menus now.'
    $report.clients_before = @(Get-XivOwners $addonRoot)
    Write-InstallerRequest $addonRoot $id; $requestWritten = $true
    Wait-XivUnloaded $addonRoot
    Stop-XivWrapper $addonRoot
    $report.state = 'installing'
    $backupRoot = Join-Path $run 'backup'
    $report.backup = $backupRoot
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    $report.changed_files = Install-XivPayload $payload $addonRoot $backupRoot
    $report.state = 'installed'; $report.finished = [DateTime]::UtcNow.ToString('o')
    if ($bootstrapInstall) { $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $bootstrapReceipt -Encoding UTF8 }
    Write-Host "Installed and verified: $($payload.Version). Reload your clients when ready."
    Write-Host "Backup/report: $run"
    if ($Package) {
        $remove = $DeletePackage
        if (!$remove) {
            try { $remove = (Read-Host 'Delete the downloaded ZIP now? [y/N]') -match '^y(es)?$' }
            catch { Write-Host 'Keeping the downloaded ZIP.'; $remove=$false }
        }
        if ($remove) {
            try { Remove-Item -LiteralPath $Package -Force; $report.download_deleted=$true }
            catch { Write-Warning "Installed successfully; could not delete ZIP: $_"; $report.download_deleted=$false }
        }
    }
} catch {
    $exitCode = 1; $report.state = 'failed'; $report.error = [string]$_
    Write-Host "Not completed: $_" -ForegroundColor Red
} finally {
    if ($requestWritten) {
        try {
            $report.acknowledgements = @(Read-InstallAcks $addonRoot $id)
            $request = Join-Path $addonRoot 'data/installer-request.ini'
            if ((Test-Path -LiteralPath $request) -and (Get-Content -LiteralPath $request -Raw) -match [regex]::Escape("id=$id")) { Remove-Item -LiteralPath $request -Force }
            Get-ChildItem -LiteralPath (Join-Path $addonRoot 'data') -Filter "installer-ack-$id-*.ini" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
        } catch { Write-Warning "Could not finish installer-request cleanup: $_" }
    }
    if (Get-Variable -Name reportPath -ErrorAction SilentlyContinue) {
        $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
        Write-Host "Report: $reportPath"
    }
    if ($lock) { $lock.Dispose() }
}
exit $exitCode
