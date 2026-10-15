<#
.SYNOPSIS
    Bulk-creates Harbor Logistics user accounts from a CSV file.

.DESCRIPTION
    Reads FirstName, LastName, Department and Title from a CSV. For each row it:
      - skips the person if an account with the same full name already exists
      - builds a username (first initial + last name, lowercase) and adds a number if it's taken
      - checks that the department has an OU (Harbor\Users\<Department>) and a group (GG-<Department>)
      - creates the account there with a temporary password the user must change at first logon
      - adds the user to the department's security group

    Supports -WhatIf to preview every change without making any.

.PARAMETER CsvPath
    Path to the CSV file. Required columns: FirstName, LastName, Department, Title.

.EXAMPLE
    .\New-HarborUsers.ps1 -CsvPath .\harbor-users.csv -WhatIf
    Shows what would be created, changes nothing.

.EXAMPLE
    .\New-HarborUsers.ps1 -CsvPath .\harbor-users.csv
    Creates the accounts. Prompts once for the temporary password.

.NOTES
    Lab script for the Harbor Logistics Active Directory home lab.
    No passwords are stored in this script or written to disk.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [string]$DomainDN  = 'DC=corp,DC=harborlogistics,DC=internal',
    [string]$UpnSuffix = 'corp.harborlogistics.internal',
    [string]$Company   = 'Harbor Logistics'
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Test-Path -Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$rows = @(Import-Csv -Path $CsvPath)
if ($rows.Count -eq 0) {
    throw "CSV file is empty: $CsvPath"
}

$requiredColumns = 'FirstName', 'LastName', 'Department', 'Title'
$csvColumns      = $rows[0].PSObject.Properties.Name
$missingColumns  = $requiredColumns | Where-Object { $_ -notin $csvColumns }
if ($missingColumns) {
    throw "CSV is missing required column(s): $($missingColumns -join ', ')"
}

# One temporary password for the batch. Every account must change it at first logon,
# so IT never knows the password the user actually uses.
if (-not $WhatIfPreference) {
    $tempPassword = Read-Host -Prompt 'Temporary password for new accounts' -AsSecureString
}

function New-Result {
    param($Name, $Username, $Department, $Result)
    [pscustomobject]@{
        Name       = $Name
        Username   = $Username
        Department = $Department
        Result     = $Result
    }
}

$results = foreach ($row in $rows) {
    $first    = $row.FirstName.Trim()
    $last     = $row.LastName.Trim()
    $dept     = $row.Department.Trim()
    $title    = $row.Title.Trim()
    $fullName = "$first $last"

    if (-not $first -or -not $last -or -not $dept) {
        New-Result $fullName '' $dept 'Skipped: missing first name, last name or department'
        continue
    }

    # 1. Department must have an OU and a security group
    $ouPath = "OU=$dept,OU=Users,OU=Harbor,$DomainDN"
    $group  = "GG-$dept"

    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'")) {
        New-Result $fullName '' $dept "Skipped: no OU for department '$dept'"
        continue
    }
    if (-not (Get-ADGroup -Filter "Name -eq '$group'")) {
        New-Result $fullName '' $dept "Skipped: no group named $group"
        continue
    }

    # 2. Skip people who already have an account (safe to run the script again)
    $safeName = $fullName.Replace("'", "''")
    $existing = Get-ADUser -Filter "Name -eq '$safeName'"
    if ($existing) {
        New-Result $fullName $existing.SamAccountName $dept 'Skipped: account already exists'
        continue
    }

    # 3. Username = first initial + last name, letters and digits only, max 20 characters
    $base = ($first.Substring(0, 1) + $last).ToLower() -replace '[^a-z0-9]', ''
    if ($base.Length -gt 20) { $base = $base.Substring(0, 20) }

    $sam = $base
    $n   = 2
    while (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        $suffix = "$n"
        $sam    = $base.Substring(0, [Math]::Min($base.Length, 20 - $suffix.Length)) + $suffix
        $n++
    }

    # 4. Create the account and add it to the department group
    if ($PSCmdlet.ShouldProcess("$fullName ($sam)", "Create user in $dept and add to $group")) {
        $userParams = @{
            Name                  = $fullName
            GivenName             = $first
            Surname               = $last
            DisplayName           = $fullName
            SamAccountName        = $sam
            UserPrincipalName     = "$sam@$UpnSuffix"
            Path                  = $ouPath
            Title                 = $title
            Department            = $dept
            Company               = $Company
            AccountPassword       = $tempPassword
            ChangePasswordAtLogon = $true
            Enabled               = $true
        }

        try {
            New-ADUser @userParams -ErrorAction Stop
            Add-ADGroupMember -Identity $group -Members $sam -ErrorAction Stop
            New-Result $fullName $sam $dept "Created, added to $group"
        }
        catch {
            New-Result $fullName $sam $dept "Failed: $($_.Exception.Message)"
        }
    }
    else {
        New-Result $fullName $sam $dept "WhatIf: would create and add to $group"
    }
}

$results | Format-Table -AutoSize | Out-String -Width 200 | Write-Host

$created = @($results | Where-Object { $_.Result -like 'Created*' }).Count
$skipped = @($results | Where-Object { $_.Result -like 'Skipped*' }).Count
$failed  = @($results | Where-Object { $_.Result -like 'Failed*' }).Count
Write-Host "Created: $created   Skipped: $skipped   Failed: $failed"
