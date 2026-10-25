# Run with Windows PowerShell 5.1 or PowerShell 7. No Windower installation needed.
$ErrorActionPreference='Stop'
$repo = Split-Path $PSScriptRoot -Parent
. (Join-Path $repo 'tools/windower_patch/WindowerPatch.ps1') -LibraryOnly
function Assert($Condition,[string]$Message) { if (!$Condition) { throw $Message } }
function Throws([scriptblock]$Body,[string]$Message) {
    $failed=$false;try { & $Body | Out-Null } catch { $failed=$true }
    Assert $failed $Message
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('windower-installer-test-'+[Guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($temp)
try {
    foreach ($name in @('../escape.lua','/absolute.lua','C:/escape.lua','data/../escape.lua','a//b.lua','CON.lua','a./test.lua','a/b .lua/..')) {
        Throws { Get-SafeRelative $name } "Accepted invalid path $name"
    }
    Assert ((Get-SafeRelative 'libs\safe.lua') -eq 'libs/safe.lua') 'Windows ZIP separators unsupported'
    foreach ($name in @('data/settings.xml','images/icon.png','run.ps1','config.ini')) { Throws { Assert-CodePath $name } 'Accepted protected/unsupported payload' }
    $stage=Join-Path $temp 'stage';$addon=Join-Path $stage 'xivcrossbar'
    $null=[IO.Directory]::CreateDirectory((Join-Path $addon 'libs'))
    [IO.File]::WriteAllText((Join-Path $addon 'xivcrossbar.lua'),"_addon.version = '0.4.0-test'")
    [IO.File]::WriteAllText((Join-Path $addon 'libs/core.lua'),'new core')
    $manifest=[ordered]@{schema=1;addon='xivcrossbar';version='0.4.0-test';source_commit='test';files=@()}
    foreach ($name in @('xivcrossbar.lua','libs/core.lua')) {
        $manifest.files+=@{path=$name;sha256=(Get-FileDigest (Join-Path $addon $name))}
    }
    $manifestPath=Join-Path $stage 'windower-patch.json'
    $manifest|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $p=Get-XivPayload $stage;Assert ($p.Files.Count -eq 2 -and $p.Version -eq '0.4.0-test') 'Manifest parsing failed'
    $root=Join-Path $temp 'Windower';$installed=Join-Path $root 'addons/xivcrossbar'
    $null=[IO.Directory]::CreateDirectory((Join-Path $installed 'data'))
    [IO.File]::WriteAllText((Join-Path $installed 'data/settings.xml'),'personal settings')
    [IO.File]::WriteAllText((Join-Path $installed 'xivcrossbar.lua'),'old version')
    $backup=Join-Path $temp 'backup'
    Assert ((Install-XivPayload $p $installed $backup) -eq 2) 'Install count wrong'
    Assert (([IO.File]::ReadAllText((Join-Path $installed 'libs/core.lua'))) -eq 'new core') 'Install failed'
    Assert (([IO.File]::ReadAllText((Join-Path $backup 'files/xivcrossbar.lua'))) -eq 'old version') 'Backup missing'
    Assert (([IO.File]::ReadAllText((Join-Path $installed 'data/settings.xml'))) -eq 'personal settings') 'Settings overwritten'
    Assert ((Install-XivPayload $p $installed (Join-Path $temp 'noop')) -eq 0) 'Identical install rewrote files'
    # Roll back both a new file and an existing file after a later injected error.
    [IO.File]::WriteAllText((Join-Path $installed 'xivcrossbar.lua'),'before rollback')
    Remove-Item -LiteralPath (Join-Path $installed 'libs/core.lua')
    $rollbackFiles=@($p.Files|Sort-Object Relative)
    $rollbackFiles+= [pscustomobject]@{Relative='libs/late.lua';Source=(Join-Path $addon 'libs/core.lua');SHA256=(Get-FileDigest (Join-Path $addon 'libs/core.lua'))}
    $rollbackPayload=[pscustomobject]@{Files=$rollbackFiles}
    $script:attempts=0
    Throws { Install-XivPayload $rollbackPayload $installed (Join-Path $temp 'rollback') {param($item) $script:attempts+=1;if($script:attempts -eq 3){throw 'injected write failure'}} } 'Injected failure was ignored'
    Assert (([IO.File]::ReadAllText((Join-Path $installed 'xivcrossbar.lua'))) -eq 'before rollback') 'Existing file not preserved'
    Assert (!(Test-Path -LiteralPath (Join-Path $installed 'libs/core.lua'))) 'New file not removed on rollback'
    # Tampered sources fail before any target writes.
    [IO.File]::WriteAllText((Join-Path $addon 'libs/core.lua'),'tampered')
    Throws { Install-XivPayload $p $installed (Join-Path $temp 'tampered') } 'Tampered source accepted'
    Assert (([IO.File]::ReadAllText((Join-Path $installed 'xivcrossbar.lua'))) -eq 'before rollback') 'Preflight changed target'
    [IO.File]::WriteAllText((Join-Path $addon 'libs/core.lua'),'new core')
    # Unlisted and unsupported manifest contents fail validation.
    [IO.File]::WriteAllText((Join-Path $addon 'unlisted.lua'),'extra')
    Throws { Get-XivPayload $stage } 'Unlisted file accepted'
    Remove-Item -LiteralPath (Join-Path $addon 'unlisted.lua')
    # Real ZIP extraction, traversal rejection and case-insensitive duplicates.
    $zip=Join-Path $temp 'good.zip';[IO.Compression.ZipFile]::CreateFromDirectory($stage,$zip)
    $unpacked=Join-Path $temp 'unpacked';Expand-CheckedZip $zip $unpacked
    Assert ((Get-XivPayload $unpacked).Files.Count -eq 2) 'ZIP roundtrip failed'
    foreach ($bad in @(@('../escape.lua'),@('xivcrossbar/A.lua','xivcrossbar/a.lua'))) {
        $badZip=Join-Path $temp ([Guid]::NewGuid().ToString()+'.zip')
        $z=[IO.Compression.ZipFile]::Open($badZip,[IO.Compression.ZipArchiveMode]::Create)
        foreach ($name in $bad) { $entry=$z.CreateEntry($name);$writer=New-Object IO.StreamWriter($entry.Open());$writer.Write('bad');$writer.Dispose() };$z.Dispose()
        Throws { Expand-CheckedZip $badZip (Join-Path $temp ([Guid]::NewGuid().ToString())) } 'Unsafe ZIP accepted'
    }
    # Legacy cumulative packages accepted, data payload rejected.
    Remove-Item -LiteralPath $manifestPath
    [IO.File]::WriteAllText((Join-Path $addon 'PATCH-INFO.txt'),'XIVcrossbar cumulative test')
    Assert ((Get-XivPayload $stage).Files.Count -eq 3) 'Legacy patch rejected'
    $null=[IO.Directory]::CreateDirectory((Join-Path $addon 'data'))
    [IO.File]::WriteAllText((Join-Path $addon 'data/settings.xml'),'not code')
    Throws { Get-XivPayload $stage } 'Legacy settings package accepted'
    # Probe actual owner-file lifetime, without testing a Windows process.
    $clients=Join-Path $installed 'data/controller-clients';$null=[IO.Directory]::CreateDirectory($clients)
    $record=Join-Path $clients '123.ini';[IO.File]::WriteAllText($record,'record')
    $owner=[IO.File]::Open($record+'.owner',[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::Read)
    try {
        Assert (@(Get-XivOwners $installed).Count -eq 1) 'Open owner was missed'
        Throws { Wait-XivUnloaded $installed 0 } 'Active owner did not prevent install'
    } finally { $owner.Dispose() }
    Assert (@(Get-XivOwners $installed).Count -eq 0) 'Released owner remained live'
    $id='a'*32;Write-InstallerRequest $installed $id
    $request=[IO.File]::ReadAllText((Join-Path $installed 'data/installer-request.ini'))
    Assert ($request -match "^\[Installer\]\nprotocol=1\nid=$id\naction=unload\nexpires=\d+\nEND\n$") 'Unload request protocol mismatch'
    [IO.File]::WriteAllText((Join-Path $installed "data/installer-ack-$id-123.ini"),"[InstallerAck]`nprotocol=1`nid=$id`nsession=123`nstate=unloading`ncharacter=Franklet`nversion=test`n")
    $acks=@(Read-InstallAcks $installed $id)
    Assert ($acks.Count -eq 1 -and $acks[0].Character -eq 'Franklet' -and $acks[0].State -eq 'unloading') 'Acknowledgement diagnostics lost'
    Stop-XivWrapper $installed # No wrapper status: no arbitrary process operation.
    [IO.File]::WriteAllText((Join-Path $installed 'data/controller-status.ini'),"[Controller]`npid=0`nstate=stopped`nclients_directory=C:\Windower\addons\xivcrossbar`n")
    Stop-XivWrapper $installed
    Assert (!(Test-Path -LiteralPath (Join-Path $installed 'data/input-stop.request'))) 'Stopped wrapper received a stop request'
    [IO.File]::WriteAllText((Join-Path $installed 'data/controller-status.ini'),"[Controller]`npid=broken`nstate=ready`n")
    Throws { Stop-XivWrapper $installed } 'Unverifiable running wrapper was ignored'
    # Exercise the real command-line orchestration, report and optional ZIP deletion.
    $cliRoot=Join-Path $temp 'CLI Windower';$null=[IO.Directory]::CreateDirectory((Join-Path $cliRoot 'addons/xivcrossbar'))
    [IO.File]::WriteAllText((Join-Path $cliRoot 'addons/xivcrossbar/xivcrossbar.lua'),'old CLI version')
    $cliZip=Join-Path $temp 'downloaded patch.zip';[IO.File]::Copy($zip,$cliZip)
    $testShell=Join-Path $PSHOME 'powershell.exe'
    if ($PSVersionTable.PSEdition -eq 'Core') { $testShell=Join-Path $PSHOME $(if([IO.Path]::DirectorySeparatorChar -eq '\'){'pwsh.exe'}else{'pwsh'}) }
    & $testShell -NoLogo -NoProfile -File (Join-Path $repo 'tools/windower_patch/WindowerPatch.ps1') -WindowerRoot $cliRoot -Package $cliZip -DeletePackage
    Assert ($LASTEXITCODE -eq 0) 'Command-line installation failed'
    Assert (!(Test-Path -LiteralPath $cliZip)) 'Opted-in ZIP deletion failed'
    $reports=@(Get-ChildItem -LiteralPath (Join-Path $cliRoot 'WindowerPatchSupport/runs') -Filter 'install-report.json' -Recurse)
    $result=Get-Content -LiteralPath $reports[0].FullName -Raw|ConvertFrom-Json
    Assert ($result.state -eq 'installed' -and $result.reload -eq 'manual' -and $result.download_deleted) 'Report missed verified result/manual reload'
    Assert (!(Test-Path -LiteralPath (Join-Path $cliRoot 'addons/xivcrossbar/data/installer-request.ini'))) 'Installer left active unload request'
    # First-run bundled bootstrap installs once and writes its completion receipt.
    $bootstrap=Join-Path $cliRoot 'WindowerPatchSupport/bootstrap'
    Copy-Item -LiteralPath $unpacked -Destination $bootstrap -Recurse
    & $testShell -NoLogo -NoProfile -File (Join-Path $repo 'tools/windower_patch/WindowerPatch.ps1') -WindowerRoot $cliRoot -DeletePackage
    Assert ($LASTEXITCODE -eq 0) 'Bundled bootstrap failed'
    Assert (Test-Path -LiteralPath (Join-Path $cliRoot 'WindowerPatchSupport/bootstrap-completed.json')) 'Bootstrap completion not retained'
    # Failure preserves the selected archive even when deletion was requested.
    & $testShell -NoLogo -NoProfile -File (Join-Path $repo 'tools/windower_patch/WindowerPatch.ps1') -WindowerRoot $cliRoot -Package $badZip -DeletePackage
    Assert ($LASTEXITCODE -ne 0 -and (Test-Path -LiteralPath $badZip)) 'Failed install deleted download'
    Write-Output 'Installer integration passed: paths, manifest/legacy ZIPs, checksums, backup, idempotence, rollback, preserved settings, archive rejection, owner lifetime and unload request.'
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
