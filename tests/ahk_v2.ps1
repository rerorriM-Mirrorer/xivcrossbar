param([Parameter(Mandatory=$true)][string]$Interpreter)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$resultPath = Join-Path $root 'native-test-results'
[void][IO.Directory]::CreateDirectory($resultPath)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('xivcrossbar ahk v2 ' + [guid]::NewGuid())
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
    $test = Start-Process $Interpreter -ArgumentList ('/ErrorStdOut "{0}"' -f (Join-Path $fixture 'native-tests.ahk')) -PassThru -RedirectStandardOutput (Join-Path $resultPath 'functions.txt') -RedirectStandardError (Join-Path $resultPath 'functions-errors.txt')
    $children += $test
    if (!$test.WaitForExit(15000)) {
        Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class DialogDump {
 public delegate bool Callback(IntPtr h, IntPtr p);
 [DllImport("user32.dll")] public static extern bool EnumWindows(Callback c, IntPtr p);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, Callback c, IntPtr p);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder b, int n);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h, uint m, IntPtr w, StringBuilder b);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
 public static string Read(int pid) {
  string result="";
  Callback read=(h,p)=> { var b=new StringBuilder(4096); SendMessageW(h,0x000D,(IntPtr)4096,b); result+=b.ToString()+"\n"; return true; };
  EnumWindows((h,p)=> {uint owner; GetWindowThreadProcessId(h,out owner); if(owner==pid) {read(h,p); EnumChildWindows(h,read,IntPtr.Zero);} return true;}, IntPtr.Zero);
  return result;
 }
}
'@
        [DialogDump]::Read($test.Id) | Tee-Object -FilePath (Join-Path $resultPath 'dialogs.txt')
        throw 'Native function tests timed out (possible runtime dialog)'
    }
    $output = Get-Content (Join-Path $resultPath 'functions.txt') -Raw
    Get-Content (Join-Path $resultPath 'functions-errors.txt')
    Write-Host $output
    if ($test.ExitCode -ne 0 -or "$output" -notmatch 'PASS native v2') { throw 'Native function tests failed' }
    # Parse optional GUI probe without opening its UI, by returning before its
    # auto-execute section. AHK parses all functions/hotkeys before executing.
    $probe = [IO.File]::ReadAllText((Join-Path $root 'tools/keyprobe/keyboard_probe.ahk'))
    [IO.File]::WriteAllText((Join-Path $fixture 'probe-parse.ahk'), "#Requires AutoHotkey v2.0+`nExitApp(0)`n" + $probe)
    $probeTest = Start-Process $Interpreter -ArgumentList ('/ErrorStdOut "{0}"' -f (Join-Path $fixture 'probe-parse.ahk')) -PassThru -RedirectStandardError (Join-Path $resultPath 'probe-errors.txt')
    $children += $probeTest
    if (!$probeTest.WaitForExit(5000) -or $probeTest.ExitCode -ne 0) { throw 'Probe v2 parse failed' }
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
    $bootstrap = Start-Process $env:ComSpec -ArgumentList ('/d /s /c ""{0}" apps ps5-extended 1"' -f (Join-Path $fixture 'launch-controller.cmd')) -PassThru -RedirectStandardError (Join-Path $resultPath 'bootstrap-errors.txt')
    $children += $bootstrap
    if (!$bootstrap.WaitForExit(10000) -or $bootstrap.ExitCode -ne 0) { throw 'CMD / Windows PowerShell bootstrap failed' }
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
    # Actual production Lua chooses the cached executable; this process launch
    # contains no CMD or PowerShell intermediary. Files/arguments contain spaces.
    $planPath = Join-Path $fixture 'direct-launch-plan.json'
    & python (Join-Path $PSScriptRoot 'controller_runtime_windows.py') $fixture $planPath
    if ($LASTEXITCODE -ne 0) { throw 'Production Lua direct-launch plan failed' }
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    if ($plan.mode -ne 'direct' -or $plan.source -ne 'cache') { throw 'Normal startup fell back to bootstrap' }
    $elapsed = [Diagnostics.Stopwatch]::StartNew()
    $direct = Start-Process -FilePath $plan.executable -ArgumentList $plan.arguments -PassThru -RedirectStandardError (Join-Path $resultPath 'direct-errors.txt')
    $children += $direct
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 10
        $status = [IO.File]::ReadAllText($statusPath)
    } while ($status -notmatch "pid=$($direct.Id)`r?`n" -and [DateTime]::UtcNow -lt $deadline -and !$direct.HasExited)
    $elapsed.Stop()
    if ($status -notmatch "pid=$($direct.Id)`r?`n" -or $direct.HasExited) { throw 'Direct executable start failed' }
    if ($status -notmatch 'device=2' -or $status -notmatch 'modifier=ctrl') { throw 'Direct start lost profile selection' }
    Copy-Item $planPath (Join-Path $resultPath 'direct-launch-plan.json')
    "PASS direct AHK start from production Lua plan; status observed after $($elapsed.ElapsedMilliseconds)ms (CI observation, not a latency guarantee)." | Tee-Object -FilePath (Join-Path $resultPath 'direct-summary.txt')
    [IO.File]::WriteAllText((Join-Path $fixture 'data\input-stop.request'), 'test')
    if (!$direct.WaitForExit(5000)) { throw 'Direct wrapper failed to stop' }
    # Preserve the original launch-file fallback when Run drops all arguments.
    [IO.File]::WriteAllText((Join-Path $fixture 'data\controller-launch.ini'), "[Controller]`r`nmodifier=ctrl`r`nprofile=ps5-extended`r`ndevice=2`r`n")
    $handoff = Start-Process $env:ComSpec -ArgumentList ('/d /s /c ""{0}""' -f (Join-Path $fixture 'launch-controller.cmd')) -PassThru -RedirectStandardError (Join-Path $resultPath 'handoff-errors.txt')
    $children += $handoff
    if (!$handoff.WaitForExit(10000) -or $handoff.ExitCode -ne 0) { throw 'Argument-free CMD bootstrap failed' }
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 50
        $status = [IO.File]::ReadAllText($statusPath)
    } while ($status -match 'pid=0' -and [DateTime]::UtcNow -lt $deadline)
    if ($status -notmatch '(?m)^pid=([1-9][0-9]*)\r?$') { throw 'Launch-file fallback did not start' }
    $handoffWrapper = Get-Process -Id ([int]$Matches[1])
    $children += $handoffWrapper
    if ($status -notmatch 'origin=launch-file' -or $status -notmatch 'device=2' -or $status -notmatch 'modifier=ctrl' -or $status -notmatch 'profile=ps5-extended') { throw 'Launch-file selection was replaced by defaults' }
    [IO.File]::WriteAllText((Join-Path $fixture 'data\input-stop.request'), 'test')
    if (!$handoffWrapper.WaitForExit(5000)) { throw 'Launch-file wrapper failed to stop' }
    # Windower is a 32-bit parent. Its ProgramFiles may point to the x86
    # installation root even though the user's v2 is installed under native PF.
    # Exercise a real WOW64 CMD -> Windows PowerShell process, no INI override.
    $nativeRoot = Join-Path $fixture 'native program files'
    $x86Root = Join-Path $fixture 'x86 program files'
    $installedV2 = Join-Path $nativeRoot 'AutoHotkey\v2'
    [void][IO.Directory]::CreateDirectory($installedV2)
    Copy-Item $Interpreter (Join-Path $installedV2 (Split-Path $Interpreter -Leaf))
    [IO.File]::Delete((Join-Path $fixture 'data\controller-runtime.ini'))
    $wowCmd = Join-Path $env:SystemRoot 'SysWOW64\cmd.exe'
    if (!(Test-Path $wowCmd)) { throw 'WOW64 CMD is required for the Windower startup regression' }
    $shim = Join-Path $fixture 'windower-32bit-launch.cmd'
    $shimBody = @'
@echo off
set "ProgramFiles={0}"
set "ProgramFiles(x86)={0}"
set "ProgramW6432={1}"
call "{2}" apps ps5-extended 1
exit /b %errorlevel%
'@ -f $x86Root, $nativeRoot, (Join-Path $fixture 'launch-controller.cmd')
    [IO.File]::WriteAllText($shim, $shimBody)
    $discovery = Start-Process $wowCmd -ArgumentList ('/d /s /c ""{0}""' -f $shim) -PassThru -RedirectStandardError (Join-Path $resultPath 'wow64-discovery-errors.txt')
    $children += $discovery
    if (!$discovery.WaitForExit(20000) -or $discovery.ExitCode -ne 0) {
        Get-Content (Join-Path $resultPath 'wow64-discovery-errors.txt')
        Get-Content (Join-Path $fixture 'data\controller-launch-error.log') -ErrorAction SilentlyContinue
        throw '32-bit Windower-style automatic v2 discovery failed'
    }
    if ([IO.File]::ReadAllText((Join-Path $fixture 'data\controller-runtime-cache.ini')) -notmatch 'bootstrap_bits=32') { throw 'Discovery fixture did not use 32-bit PowerShell' }
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 50
        $status = [IO.File]::ReadAllText($statusPath)
    } while ($status -match 'pid=0' -and [DateTime]::UtcNow -lt $deadline)
    if ($status -notmatch '(?m)^pid=([1-9][0-9]*)\r?$') { throw 'Automatic discovery did not start the wrapper' }
    $discoveredWrapper = Get-Process -Id ([int]$Matches[1])
    $children += $discoveredWrapper
    if (!$status.Contains($installedV2)) { throw 'Discovery did not use native Program Files interpreter' }
    Copy-Item $statusPath (Join-Path $resultPath 'wow64-status.ini')
    [IO.File]::WriteAllText((Join-Path $fixture 'data\input-stop.request'), 'test')
    if (!$discoveredWrapper.WaitForExit(5000)) { throw 'Automatically discovered wrapper failed to stop' }
    'PASS actual 32-bit CMD/PowerShell discovers v2 in native Program Files without an override.' | Tee-Object -FilePath (Join-Path $resultPath 'wow64-summary.txt')
    # A wrong executable override must fail closed, without association fallback.
    $wrongRuntime = (Get-Command powershell.exe).Source
    [IO.File]::WriteAllText((Join-Path $fixture 'data\controller-runtime.ini'), "[Runtime]`r`nexecutable=$wrongRuntime`r`n")
    $rejected = Start-Process $env:ComSpec -ArgumentList ('/d /s /c ""{0}" apps ps5-extended 1"' -f (Join-Path $fixture 'launch-controller.cmd')) -PassThru -RedirectStandardError (Join-Path $resultPath 'expected-rejection.txt')
    $children += $rejected
    if (!$rejected.WaitForExit(10000) -or $rejected.ExitCode -eq 0) { throw 'Non-v2 override was not rejected' }
    if (!(Test-Path (Join-Path $fixture 'data\controller-launch-error.log'))) { throw 'Bootstrap error log missing' }
    Copy-Item $statusPath (Join-Path $resultPath 'final-status.ini')
    'PASS native v2 parse, policies, startup, installation mutex, explicit stop, bootstrap and restart. No FFXI/controller attached.' | Tee-Object -FilePath (Join-Path $resultPath 'summary.txt')
} finally {
    foreach ($child in $children) { if (!$child.HasExited) { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue } }
    Remove-Item $fixture -Recurse -Force -ErrorAction SilentlyContinue
}
