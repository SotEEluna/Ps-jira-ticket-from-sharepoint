Clear-Host
try {
    Write-Host -ForegroundColor yellow "[INFO]: Try to import the loggin module:"
    Import-Module "$($PSScriptRoot)\modules\logging.psm1" -Force -ErrorAction Stop
    Write-Log "$($PSScriptRoot)\modules\logging.psm1 successfully imported" SUCCESS
}
catch {
    Write-Host -ForegroundColor Red "$($PSScriptRoot)\modules\logging.psm1 could not be imported successfully"
    Write-Host -ForegroundColor Red "$($_.Exception.Message)"
    Pause
}

$modulePaths = @(
    Join-Path $PSScriptRoot -ChildPath 'modules\config.psm1'
    Join-Path $PSScriptRoot -ChildPath 'modules\output.psm1'
    Join-Path $PSScriptRoot -ChildPath 'modules\SPConnection.psm1'
)

Write-Log "Import all necessary modules:"

foreach ($path in $modulePaths) {
    try {
        Import-Module "$($path)" -Force
        Write-Log "$path : imported." SUCCESS
    }
    catch {
        Write-Log "$path : could not be imported." ERROR
        Write-Log "$($_.Exception.Message)" ERROR
        Write-Log "Exit Script." ERROR
        Pause
        exit
        }
}






