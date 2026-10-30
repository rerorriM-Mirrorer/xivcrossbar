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
    Copy-Item $statusPath (Join-Path $resultPath 'final-status.ini')
    'PASS native v2 parse, policies, startup, installation mutex, explicit stop, bootstrap and restart. No FFXI/controller attached.' | Tee-Object -FilePath (Join-Path $resultPath 'summary.txt')
} finally {
    foreach ($child in $children) { if (!$child.HasExited) { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue } }
    Remove-Item $fixture -Recurse -Force -ErrorAction SilentlyContinue
}
