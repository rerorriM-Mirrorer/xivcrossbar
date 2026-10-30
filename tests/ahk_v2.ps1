param([Parameter(Mandatory=$true)][string]$Interpreter)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $root 'native-test-results'
[void][IO.Directory]::CreateDirectory($resultPath)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('xivcrossbar-ahk-v2-' + [guid]::NewGuid())
[void][IO.Directory]::CreateDirectory($fixture)
$children = @()
try {
    $Interpreter = (Resolve-Path -LiteralPath $Interpreter).Path
    $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($Interpreter)
    if ($version.FileMajorPart -ne 2) { throw 'Native tests require an actual v2 executable' }
    foreach ($file in @('ffxi_directinput.ahk','controller_messages.ahk','personal_controls.ahk','personal_gestures.ahk','controller_clients.ahk','movement_signal.ahk','launch-controller.cmd','launch-controller.ps1')) {
        Copy-Item -LiteralPath (Join-Path $root $file) -Destination $fixture
    }
    Copy-Item (Join-Path $PSScriptRoot 'ahk_v2.ahk') (Join-Path $fixture 'native-tests.ahk')
    $source = [IO.File]::ReadAllText((Join-Path $fixture 'ffxi_directinput.ahk'))
    $functions = $source.Substring($source.IndexOf("`nAcquireWrapperMutex() {") + 1)
    [IO.File]::WriteAllText((Join-Path $fixture 'runtime-functions.ahk'), $functions)
    $output = & $Interpreter /ErrorStdOut (Join-Path $fixture 'native-tests.ahk') 2>&1
    $output | Tee-Object -FilePath (Join-Path $resultPath 'functions.txt')
    if ($LASTEXITCODE -ne 0 -or "$output" -notmatch 'PASS native v2') { throw 'Native function tests failed' }
    # Parse optional GUI probe without opening its UI, by returning before its
    # auto-execute section. AHK parses all functions/hotkeys before executing.
    $probe = [IO.File]::ReadAllText((Join-Path $root 'tools/keyprobe/keyboard_probe.ahk'))
    [IO.File]::WriteAllText((Join-Path $fixture 'probe-parse.ahk'), "#Requires AutoHotkey v2.0+`nExitApp(0)`n" + $probe)
    & $Interpreter /ErrorStdOut (Join-Path $fixture 'probe-parse.ahk')
    if ($LASTEXITCODE -ne 0) { throw 'Probe v2 parse failed' }
    $statusPath = Join-Path $fixture 'data\controller-status.ini'
    Remove-Item (Join-Path $fixture 'data\test.buttons') -ErrorAction SilentlyContinue
    # All active-wrapper execution is isolated; no real game or user data.
    $arguments = '/ErrorStdOut "{0}" apps ps5-extended 1' -f (Join-Path $fixture 'ffxi_directinput.ahk')
    $child = Start-Process $Interpreter -ArgumentList $arguments -PassThru -RedirectStandardError (Join-Path $resultPath 'wrapper-stderr.txt') -RedirectStandardOutput (Join-Path $resultPath 'wrapper-stdout.txt')
    $children += $child
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (!(Test-Path $statusPath) -and [DateTime]::UtcNow -lt $deadline -and !$child.HasExited) { Start-Sleep -Milliseconds 50; $child.Refresh() }
    if (!(Test-Path $statusPath)) { throw 'Wrapper failed to publish startup status' }
    $status = [IO.File]::ReadAllText($statusPath)
    if ($status -notmatch 'ahk_major=2' -or $status -notmatch "pid=$($child.Id)`r?`n") { throw 'Wrong wrapper/interpreter status' }
    $duplicate = Start-Process $Interpreter -ArgumentList $arguments -PassThru
    $children += $duplicate
    if (!$duplicate.WaitForExit(5000)) { throw 'Duplicate wrapper did not exit' }
    if ($child.HasExited) { throw 'Duplicate stopped the original' }
    [IO.File]::WriteAllText((Join-Path $fixture 'data\input-stop.request'), 'test')
    if (!$child.WaitForExit(5000)) { throw 'Explicit stop failed' }
    $status = [IO.File]::ReadAllText($statusPath)
    if ($status -notmatch 'state=stopped' -or $status -notmatch 'pid=0') { throw 'Stop cleanup status missing' }
    # Verify bootstrap path with spaces, explicit v2 override and restart.
    [IO.File]::WriteAllText((Join-Path $fixture 'data\controller-runtime.ini'), "[Runtime]`r`nexecutable=$Interpreter`r`n")
    & (Join-Path $fixture 'launch-controller.ps1') apps ps5-extended 1
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 50
        $status = [IO.File]::ReadAllText($statusPath)
    } while ($status -match 'pid=0' -and [DateTime]::UtcNow -lt $deadline)
    if ($status -notmatch '(?m)^pid=([1-9][0-9]*)\r?$') { throw 'Bootstrap restart failed' }
    $restart = Get-Process -Id ([int]$Matches[1])
    $children += $restart
    [IO.File]::WriteAllText((Join-Path $fixture 'data\input-stop.request'), 'test')
    if (!$restart.WaitForExit(5000)) { throw 'Restarted wrapper failed to stop' }
    Copy-Item $statusPath (Join-Path $resultPath 'final-status.ini')
    'PASS native v2 parse, policies, startup, installation mutex, explicit stop, bootstrap and restart. No FFXI/controller attached.' | Tee-Object -FilePath (Join-Path $resultPath 'summary.txt')
} finally {
    foreach ($child in $children) { if (!$child.HasExited) { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue } }
    Remove-Item $fixture -Recurse -Force -ErrorAction SilentlyContinue
}
