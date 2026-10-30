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
        foreach ($installRoot in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
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
        if ($version.FileMajorPart -eq 2 -and $version.ProductName -match 'AutoHotkey') {
            $interpreter = $candidate; break
        }
    }
    if (-not $interpreter) { throw 'AutoHotkey v2 was not found. Install v2 or set data/controller-runtime.ini [Runtime] executable=C:\path\AutoHotkey64.exe. v1 is never used as a fallback.' }
    $script = Join-Path $PSScriptRoot 'ffxi_directinput.ahk'
    $arguments = '/ErrorStdOut "{0}" {1} {2} {3}' -f $script, $Modifier, $Profile, $Device
    Start-Process -FilePath $interpreter -ArgumentList $arguments -WorkingDirectory $PSScriptRoot
} catch {
    $message = '{0:u} {1}' -f [DateTime]::UtcNow, $_.Exception.Message
    [IO.File]::AppendAllText((Join-Path $PSScriptRoot 'data\controller-launch-error.log'), $message + [Environment]::NewLine)
    Write-Error $message
    exit 1
}
