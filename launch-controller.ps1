# Independent bootstrap; no launcher app or .ahk association is required.
param(
    [ValidateSet('apps','ctrl')][string]$Modifier = 'apps',
    [ValidateSet('ps5-directinput','ps5-extended','f710-directinput','fightpadpro-directinput','xinput','xinput-r1-chooser','xinput-extended')][string]$Profile = 'ps5-directinput',
    [ValidateRange(1,16)][int]$Device = 1
)
$ErrorActionPreference = 'Stop'
try {
    $dataPath = Join-Path $PSScriptRoot 'data'
    [void][IO.Directory]::CreateDirectory($dataPath)
    $overridePath = Join-Path $dataPath 'controller-runtime.ini'
    $explicitPath = $null
    if (Test-Path -LiteralPath $overridePath) {
        $section = ''
        foreach ($line in [IO.File]::ReadAllLines($overridePath)) {
            if ($line -match '^\s*\[([^]]+)\]\s*$') { $section = $Matches[1]; continue }
            if ($section -eq 'Runtime' -and $line -match '^\s*executable\s*=\s*(.*?)\s*$') {
                $explicitPath = $Matches[1].Trim('"')
            }
        }
        if (-not $explicitPath) { throw 'controller-runtime.ini needs [Runtime] executable= with an absolute v2 executable path.' }
    }
    $candidates = @()
    if ($explicitPath) {
        if (-not [IO.Path]::IsPathRooted($explicitPath)) { throw 'The configured AutoHotkey executable must be an absolute path.' }
        $candidates = @($explicitPath)
    } else {
        # A 32-bit Windower/Run parent makes ProgramFiles resolve to the
        # x86 root. ProgramW6432 retains the native 64-bit install location.
        # Keep the same verified v2 executables and strict override behavior.
        foreach ($installRoot in @($env:ProgramW6432, $env:ProgramFiles, ${env:ProgramFiles(x86)})) {
            if ($installRoot) {
                $candidates += Join-Path $installRoot 'AutoHotkey\v2\AutoHotkey64.exe'
                $candidates += Join-Path $installRoot 'AutoHotkey\v2\AutoHotkey32.exe'
            }
        }
    }
    $interpreter = $null
    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($candidate)
        if ($version.FileMajorPart -eq 2 -and ($version.FileMinorPart -gt 0 -or $version.FileBuildPart -ge 19) -and $version.ProductName -match 'AutoHotkey') {
            $interpreter = $candidate; break
        }
    }
    if (-not $interpreter) {
        $discovery = 'bootstrap_bits={0}; checked={1}' -f ([IntPtr]::Size * 8), ($candidates -join ' | ')
        throw ('AutoHotkey v2.0.19+ was not found. Install v2 or set data/controller-runtime.ini [Runtime] executable=C:\path\AutoHotkey64.exe. v1 is never used as a fallback. ' + $discovery)
    }
    $script = Join-Path $PSScriptRoot 'ffxi_directinput.ahk'
    # Run-plugin versions can drop arguments. In that case let the wrapper
    # consume Lua's existing controller-launch.ini handoff instead of replacing
    # the selected extended profile with bootstrap parameter defaults.
    $arguments = if ($PSBoundParameters.ContainsKey('Profile')) {
        '/ErrorStdOut "{0}" {1} {2} {3}' -f $script, $Modifier, $Profile, $Device
    } else {
        '/ErrorStdOut "{0}"' -f $script
    }
    Start-Process -FilePath $interpreter -ArgumentList $arguments -WorkingDirectory $PSScriptRoot
} catch {
    $message = '{0:u} {1}' -f [DateTime]::UtcNow, $_.Exception.Message
    [IO.File]::AppendAllText((Join-Path $PSScriptRoot 'data\controller-launch-error.log'), $message + [Environment]::NewLine)
    Write-Error $message
    exit 1
}
