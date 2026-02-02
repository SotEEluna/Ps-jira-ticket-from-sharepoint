# This Function Logs the events of the whole tool:

$path = "$(Join-Path (Split-Path $PSScriptRoot -Parent)\logs\"
$logfile = "$($path)\(Get-Date -format 'd')_log.txt"

if (-not(Test-Path $logfile) {
  New-Item -ItemType File -Force -Path $logfile | Out-Null
}

function Write-Log {
  param (
      $text
  )
  "$($text)" | Out-File $logfile -Append
}
