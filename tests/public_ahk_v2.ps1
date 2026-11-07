param([Parameter(Mandatory)][string]$Interpreter)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $env:RUNNER_TEMP ('xivcrossbar public v2 ' + [Guid]::NewGuid())
$data = Join-Path $stage 'data'
[void][IO.Directory]::CreateDirectory($data)
foreach ($name in @('ffxi_directinput.ahk','controller_messages.ahk','controller_diagnostics.ahk','controller_clients.ahk','launch-controller.cmd','launch-controller.ps1','tests/public_ahk_v2.ahk')) {
    Copy-Item (Join-Path $root $name) $stage
}
$status = Join-Path $data 'controller-status.ini'
$stop = Join-Path $data 'input-stop.request'
$runtime = Join-Path $data 'controller-runtime.ini'
$launch = Join-Path $data 'controller-launch.ini'
$script = Join-Path $stage 'ffxi_directinput.ahk'
function Await-Status([string]$pattern) {
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        try { $contents = [IO.File]::ReadAllText($status) } catch { $contents = '' }
        if ($contents -match $pattern) { return $contents }
        Start-Sleep -Milliseconds 100
    }
    throw "Missing status '$pattern'. Last status: $contents"
}
function Start-Reader([string]$arguments) {
    Start-Process -FilePath $Interpreter -ArgumentList ('/ErrorStdOut "{0}" {1}' -f $script, $arguments) -PassThru
}
try {
    $fixture = Join-Path $stage 'public_ahk_v2.ahk'
    $unit = Start-Process -FilePath $Interpreter -ArgumentList ('/ErrorStdOut "{0}"' -f $fixture) -PassThru -NoNewWindow
    if (!$unit.WaitForExit(10000) -or $unit.ExitCode -ne 0) { throw 'Native DirectLink fixture failed' }
    Set-Content $runtime @('[Runtime]', "executable=$Interpreter")
    Set-Content $launch @('[Controller]', 'profile=f710-directinput', 'device=2', 'modifier=ctrl')
    & (Join-Path $stage 'launch-controller.cmd')
    if ($LASTEXITCODE -ne 0) { throw 'Bootstrap failed' }
    $first = Await-Status '(?m)^pid=[1-9]\d*$'
    if ($first -notmatch 'origin=launch-file' -or $first -notmatch 'profile=f710-directinput' -or
        $first -notmatch 'device=2' -or $first -notmatch 'modifier=ctrl' -or $first -notmatch 'ahk=2\.') {
        throw "Incorrect fallback selection: $first"
    }
    $readerPid = [int][regex]::Match($first, '(?m)^pid=(\d+)').Groups[1].Value
    $duplicate = Start-Reader 'apps ps5-directinput 1'
    if (!$duplicate.WaitForExit(5000) -or $duplicate.ExitCode -ne 0) { throw 'Duplicate reader did not exit cleanly' }
    $after = Await-Status "(?m)^pid=$readerPid$"
    if ($after -notmatch 'profile=f710-directinput') { throw 'Duplicate replaced the running selection' }
    $firstProcess = Get-Process -Id $readerPid
    Set-Content $stop 'stop'
    [void](Await-Status 'state=stopped')
    if (!$firstProcess.WaitForExit(5000)) { throw 'Reader did not stop' }

    foreach ($profile in @('ps5-directinput','f710-directinput','fightpadpro-directinput','xinput','xinput-r1-chooser')) {
        $reader = Start-Reader "apps $profile 1"
        $selection = Await-Status "(?m)^pid=$($reader.Id)$"
        if ($selection -notmatch "(?m)^profile=$profile$" -or $selection -notmatch 'origin=arguments') {
            throw "Wrong explicit profile: $selection"
        }
        Set-Content $stop 'stop'
        [void](Await-Status 'state=stopped')
        if (!$reader.WaitForExit(5000)) { throw "Could not stop $profile" }
    }
    Set-Content $runtime @('[Runtime]', "executable=$env:ComSpec")
    & (Join-Path $stage 'launch-controller.cmd')
    if ($LASTEXITCODE -eq 0) { throw 'Bootstrap accepted a non-AHK executable' }
    # GitHub's pwsh wrapper exits with the last native process code.
    $global:LASTEXITCODE = 0
    Write-Host 'Public native bootstrap, duplicate rejection, explicit stop and all five profile selections passed.'
} finally {
    if (Test-Path $status) {
        Get-Content $status
        Set-Content $stop 'stop'
    }
    $launchError = Join-Path $data 'controller-launch-error.log'
    if (Test-Path $launchError) { Get-Content $launchError }
}
