# Create a Log File and start logging for the script:
$path = "$(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)\logs\"
$logfile = "$($path)$(Get-Date -Format 'd')_log.txt"

if (-not (Test-Path $logfile)) {
    New-Item -ItemType File -Path $logfile -Force | Out-Null
}
else {
    Clear-Content -Path $logfile -Force
}


function Write-Log {
    param(
        $text,
        [ValidateSet('INFO','SYS','ERROR','SUCCESS')][string]$level = 'INFO'  
    )
    "[$(Get-Date -Format 'HH:mm:ss')][$($level)]: $($text)" | Out-File -FilePath $logfile -Append
   
    switch ($level) {
        "INFO" {
            Write-Host -ForegroundColor Yellow "[$($level)]: $($text)"
        }
        "ERROR" {
            Write-Host -ForegroundColor Red "[$($level)]: $($text)"
        }
        "SYS" {
            Write-Host -ForegroundColor Cyan "[$($level)]: $($text)"
        }
        "SUCCESS" {
            Write-Host -ForegroundColor Green "[$($level)]: $($text)"
        }
        Default {"INFO"}
    }
}

Export-ModuleMember -Function Write-Log
