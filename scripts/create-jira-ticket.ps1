Clear-Host

import-Module PnP.Powershell -RequiredVersion "1.11.0"

#region "CONFIG"

    $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'config\config.json'
    $config = Get-Content $configPath -Raw |ConvertFrom-Json

#endregion

#region "LOGFILE"

    $path = Join-Path (Split-Path $PSScriptRoot -Parent) 'logs\'
    $logfile = "$($path)logfile_createJiraTicket.txt"

    if (-not (Test-Path $logfile)) {

        New-Item -ItemType File -Force -Path $logfile | Out-Null
    }

#endregion

#region "FUNCTIONS"
    # Create Logfile and Fill it with events
    function Write-Log {
        param (
            $text
        )
        "$($text)" | Out-File $logfile -Append
        
    }

    # Connect to SharePoint Online and export SharePoint Online List local to csv
    function spQuery {
        $SiteURL = $config.SharePoint.SiteURL
        $ListNameSpOnline = $config.SharePoint.ListName
        $csvPathSpData = "$($path)ListCalendar.csv"
        $ListDataCollection = @()

        Connect-PnPOnline -Url $SiteURL -UseWebLogin
        $ListItems = Get-PnPListItem -List $ListNameSpOnline -PageSize 2000

        foreach ($item in $ListItems) {
            $ListDataCollection += New-Object PSObject -Property @{
                            Title          = $Item["Title"]            
                            Location = $Item["Location"]
                            EndDate=  $Item["EndDate"]
                            Category = $Item["Category"]
                        }
        }

        $ListDataCollection | Export-Csv $csvPathSpData -NoTypeInformation

        
    }

    <# In my case, I export a team calendar to retrieve the start dates of new employees and automatically generate a Jira ticket for each one#>
    function evaluationNewEmployes {
        param ($Date)

        $csvPath = "$($path)ListCalendar.csv"
        $csvData = Import-Csv -Path $csvPath -Delimiter ","
        $endTime ="$($Date) 23:59:00"
        $arrayDataTrue = @()
        $arrayDataFalse = @()

                foreach ($user in $csvData)
        {
            if ($user.Title -like "New Employee*" -AND $user.EndDate -eq $endTime)
            {
                
                try
                {
 
                    [string]$userDN = $user.Title -split "New Employee"
                    $userDN = $userDN.Replace("  ","")
                    [string]$userSamAccountName = Get-ADUser -filter {displayName -like $userDN} | Select-Object samAccountName
                    $userSamAccountName = [string]$userSamAccountName.Split("=").split("}")[1]                        
                    $choise = ShouldCreateJiraTicket $userDN
                    

                    if ($choise -eq $true)
                    {
                        $enDate = (Get-Date $Date).ToString('yyyy-MM-dd')

                        # Template klonen (je nach JSON Struktur)
                        $bodyObj = $config.Jira.BodyTemplate | ConvertTo-Json -Depth 50 | ConvertFrom-Json
                        # oder: $bodyObj = $config.JiraBodyTemplate | ConvertTo-Json -Depth 50 | ConvertFrom-Json

                        $bodyObj.fields.project.key        = $config.Jira.ProjectKey
                        $bodyObj.fields.issuetype.name     = $config.Jira.IssueType
                        $bodyObj.fields.summary            = $config.Jira.DefaultSummary
                        $bodyObj.fields.description        = "Your Description AD or SharePoint"
                        $bodyObj.fields.components[0].id   = $config.Jira.ComponentId
                        $bodyObj.fields.labels             = @($userSamAccountName, "new Employee")
                        $bodyObj.fields.duedate            = $enDate            # <-- FIX
                        $bodyObj.fields.priority.id        = $config.Jira.PriorityId

                        $body = $bodyObj | ConvertTo-Json -Depth 50


                        $JiraUsername = $config.Jira.Username
                        $JiraPassword = $config.Jira.ApiToken


                        try 
                        {
                            $basicAuth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($JiraUsername):$JiraPassword"))
                            $headers = @{
                            "Authorization" = $basicAuth
                            "Content-Type"  = "application/json; charset=utf-8";
                            }

                            $requestUri = $config.Jira.RequestUri
                            $response = Invoke-RestMethod -Uri $requestUri -Method POST -Headers $headers -Body $body -UseBasicParsing -ContentType "application/json; charset=utf-8";
                            


                            $logds = "$($userSamAccountName) $($userDN) $($user.Location) $($response.key)"
                            $arrayDataTrue = $arrayDataTrue + $logds
                                
                        }
                        catch
                        {
                            Write-Warning "Remote Server Response: $($_.Exception.Message)"
                            Write-Output "Status Code: $($_.Exception.Response.StatusCode)"
                        }
                        
                    }
                    
                    else 
                    {
                        $logds = "$($userSamAccountName) $($userDN) $($user.Location) no Ticket created."
                        $arrayDataFalse = $arrayDataFalse + $logds
                    }
                                        
                }
                catch
                {
                    Write-Host "For the user $($userDN) couldn't be created a ticket."
                    Write-Host "Look in the Logfile: '$($logfile)' for more details."
                    continue
                    
                }   
            }
        }     

        Write-Host "Users for which a ticket has been generated:"
        Write-Log -text "User für die ein Ticket erstellt wurde:"
        foreach ($array in $arrayDataTrue) {
            Write-Host $array
            Write-Log -text $array
        }

        Write-Host ""
        Write-Host ""
        Write-Log ""
        Write-Log ""

        Write-Host -ForegroundColor Red "Users for whom tickets have not been created:"
        Write-Log -text "Users for whom tickets have not been created"
        foreach ($arrayFalse in $arrayDataFalse) {
            Write-Host $arrayFalse
            Write-Log -text $arrayFalse
        }
        Write-Host ""
        Write-Host ""
    }

    function ShouldCreateJiraTicket {
        param ($user)
        $selectedChoise = $host.UI.Prompt.PromptForChoice("Select", "Should be for $($user) a Jira-Ticket be generated?", ('&NO', '&YES'), 0)

        switch ($selectedChoise) {
            0 { # No
                return $false
            }

            1 { # Yes
                return $true
            }

            2 { #nothing

                return $false
            }
            
        }
    }
#endregion

#region "WORKFLOW"

Write-Host -ForegroundColor Cyan "Download Data from SharePoint..."
spQuery

$Date = $(Write-Host -ForegroundColor Cyan "Please enter the start Date of the entry: " -NoNewline; Read-Host)
evaluationNewEmployes $Date

Remove-Item -Path "$($path)ListCalendar.csv"
Start-Process -FilePath $logfile

Write-Host -ForegroundColor Cyan "Enter to close the script."
Pause

#endregion





