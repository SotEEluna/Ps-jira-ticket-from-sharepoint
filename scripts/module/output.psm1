# Create a File for the result of the Script
$path = "$(Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)\output\"
$resultFile = "$($path)$(Get-Date -Format 'd')_result.txt"

if (-not(Test-Path $resultFile)) {
    New-Item -ItemType File -Path $resultFile -Force| Out-Null
}
else {
    Clear-Content -Path $resultFile -Force
}

function Write-Result {
    param(
        $text
    )
    "$($text)" | Out-File -FilePath $resultFile -Append
}

Export-ModuleMember -Function Write-Result
