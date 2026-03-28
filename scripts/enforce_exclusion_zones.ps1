param(
    [string]$RootDir = ".",
    [int]$SpikeStaleHours = 48,
    [switch]$FailOnStaleSpike
)

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
}

if (-not $python) {
    Write-Error "Python is required for exclusion checks."
    exit 2
}

$helper = Join-Path $PSScriptRoot 'enforce_exclusion_zones.py'
$args = @(
    $helper,
    '--root', $RootDir,
    '--spike-stale-hours', $SpikeStaleHours
)

if ($FailOnStaleSpike.IsPresent) {
    $args += '--fail-on-stale-spikes'
}

if ($python.Name -ieq 'py.exe') {
    & $python.Source -3 @args
} else {
    & $python.Source @args
}

exit $LASTEXITCODE
