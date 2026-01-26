
# Create Jira Tickets for New Employees (from SharePoint Calendar)

This project is a PowerShell-based automation that creates **Jira tickets** for **new employees** by reading structured data from a **SharePoint Online calendar/list**. It evaluates employee start dates, prompts the operator for confirmation, and creates Jira issues accordingly. The script includes CSV export, Active Directory lookups, configurable Jira request bodies, and detailed logging.

---

## 📌 Overview
This script automates the workflow for onboarding new employees by:
- Querying a SharePoint Online list using **PnP.PowerShell**
- Exporting list items into a CSV
- Identifying entries with titles matching `New Employee*`
- Asking the operator whether a Jira ticket should be created for each entry
- Generating Jira tickets through the **Jira REST API**
- Logging all actions for auditing and troubleshooting

This ensures consistency, reduces manual processing effort, and centralizes onboarding tasks.

---

## 🚀 Features

### 🔹 SharePoint Integration
- Authenticates via `Connect-PnPOnline -UseWebLogin`
- Retrieves list items from a configurable list and site
- Extracts fields such as `Title`, `Location`, `EndDate`, `Category`

### 🔹 Data Processing
- Exports SharePoint entries into `logs/ListCalendar.csv`
- Filters for entries where:
  - `Title` begins with `New Employee`
  - `EndDate` = *selected date at 23:59*

### 🔹 Active Directory Lookup
Uses `Get-ADUser` to extract the employee's `samAccountName` from their display name.

### 🔹 Jira Ticket Creation
- Fully configurable Jira payload via `config.json`
- REST API request with Basic Authentication
- Automatically fills fields:
  - Project
  - Issue Type
  - Summary
  - Description
  - Components
  - Labels (including samAccountName)
  - Due Date
  - Priority

### 🔹 Logging
- All results written to: `logs/logfile_createJiraTicket.txt`
- Displays users for whom tickets were or were not created
- Automatically opens the logfile after execution

---

## 📁 Project Structure
```
Config/
  config.json
logs/
  .gitkeep
scripts/
  create-jira-ticket.ps1
.gitignore
README.md
License
```

### Folder Purpose
| Folder/File | Purpose |
|-------------|---------|
| `Config/config.json` | Holds SharePoint & Jira configuration |
| `logs/` | Contains log output and temporary CSV exports |
| `scripts/create-jira-ticket.ps1` | Main automation script |
| `.gitignore` | Ensures sensitive/log files are not committed |
| `README.md` | Documentation |
| `License` | License information |

---

## 🔧 Requirements

### Software
- **PowerShell 5.1** or **PowerShell 7+**
- **PnP.PowerShell (1.11.0)**
- **Active Directory module** (RSAT)

### Permissions
- Access to the SharePoint site & list
- Jira service account with sufficient ticket creation permissions
- Ability to read AD user information

---

## ⚙️ Configuration File (`config.json`)
The configuration file contains all necessary parameters for SharePoint and Jira.

Example:
```json
{
  "SharePoint": {
    "SiteURL": "https://sharepoint.example.com/sites/company",
    "ListName": "SharePoint.Example.List"
  },
  "Jira": {
    "RequestUri": "Your-Request-Uri-For Jira",
    "ApiToken": "example.API-Token-to-your-project",
    "Username": "Username of Your Jira Service-User",
    "ProjectKey": "Your-Project-Key",
    "IssueType": "Your-Issue-Type",
    "DefaultSummary": "Your Ticket Summary",
    "ComponentId": "12345",
    "PriorityId": "3",
    "BodyTemplate": {
      "fields": {
        "project": { "key": "" },
        "issuetype": { "name": "" },
        "summary": "",
        "description": "",
        "components": [ { "id": "" } ],
        "labels": [],
        "duedate": "",
        "priority": { "id": "" }
      }
    }
  }
}
```

You can extend this structure to support more Jira fields.

---

## 🧠 Script Logic (Detailed)

### 1️⃣ Load configuration
Reads the JSON configuration and initializes paths.

### 2️⃣ Initialize logfile
Ensures that the logfile exists in the `logs/` directory.

### 3️⃣ Query SharePoint
- Connects to SharePoint Online
- Retrieves all list items
- Exports selected fields into CSV

### 4️⃣ Input date
The operator enters the date for which new employee entries should be evaluated.

### 5️⃣ Process CSV
For each matching entry:
- Parse displayName
- Extract `samAccountName` from Active Directory
- Prompt user whether a Jira ticket should be created for this employee

### 6️⃣ Create Jira Ticket
If approved:
- Clone & fill the JSON template
- Perform REST POST request
- Log success/failure

### 7️⃣ Cleanup & Output
- CSV is deleted
- Logfile is displayed
- Script waits for final user confirmation before closing

---

## ▶️ Usage
From the project root, run:
```powershell
pwsh ./scripts/create-jira-ticket.ps1
```
Or using Windows PowerShell:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ./scripts/create-jira-ticket.ps1
```
Follow the console prompts:
1. Enter date
2. Confirm ticket creation per user
3. Review results in logfile

---

## 📝 Logs
Logfile path:
```
logs/logfile_createJiraTicket.txt
```
The log contains:
- All created Jira tickets
- All skipped employees
- Errors during REST or AD lookup

---

## 🔒 Security Notes
- Do **not** commit real API tokens
- Consider using environment variables or a secret vault
- Restrict access to `config.json`

---

## 📄 License
See the `License` file.

---
