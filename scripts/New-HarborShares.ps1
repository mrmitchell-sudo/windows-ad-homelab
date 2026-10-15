<#
.SYNOPSIS
    Creates the Harbor Logistics department file share using AGDLP.

.DESCRIPTION
    Builds one share, \\DC01\Departments, with a subfolder per department.

      Accounts -> Global groups -> Domain Local groups -> Permissions (AGDLP)
      jreyes   -> GG-Finance    -> DL-Share-Finance-Modify -> Modify on Departments\Finance

    For each department it:
      - creates a domain local group DL-Share-<Dept>-Modify (if it doesn't exist)
      - nests the department's global group GG-<Dept> inside it
      - creates C:\Shares\Departments\<Dept> with inheritance removed and
        NTFS permissions: SYSTEM and Administrators Full Control, the DL group Modify

    The share uses Access-Based Enumeration, so users only see the
    department folders they have permission to open.

.NOTES
    Lab script for the Harbor Logistics Active Directory home lab.
    In production, file shares belong on a dedicated file server, not a domain controller.
#>
[CmdletBinding()]
param(
    [string[]]$Departments = @('IT', 'HR', 'Finance'),
    [string]$RootPath      = 'C:\Shares\Departments',
    [string]$ShareName     = 'Departments',
    [string]$NetBiosDomain = 'HARBOR',
    [string]$GroupsOU      = 'OU=Groups,OU=Harbor,DC=corp,DC=harborlogistics,DC=internal'
)

Import-Module ActiveDirectory -ErrorAction Stop

# 1. Root folder: admins have full control; everyone signed in can open the root
#    (this folder only), but not the department folders below it.
New-Item -Path $RootPath -ItemType Directory -Force | Out-Null
icacls $RootPath /inheritance:r /grant:r `
    'SYSTEM:(OI)(CI)F' `
    'BUILTIN\Administrators:(OI)(CI)F' `
    'NT AUTHORITY\Authenticated Users:RX' | Out-Null
Write-Host "Root folder ready: $RootPath"

foreach ($dept in $Departments) {
    $globalGroup = "GG-$dept"
    $localGroup  = "DL-Share-$dept-Modify"
    $folder      = Join-Path $RootPath $dept

    if (-not (Get-ADGroup -Filter "Name -eq '$globalGroup'")) {
        Write-Warning "Skipping $dept : global group $globalGroup not found"
        continue
    }

    # 2. Domain local group = permission on this one resource
    if (-not (Get-ADGroup -Filter "Name -eq '$localGroup'")) {
        New-ADGroup -Name $localGroup -GroupScope DomainLocal -GroupCategory Security `
            -Path $GroupsOU -Description "Modify access to \\$env:COMPUTERNAME\$ShareName\$dept"
        Write-Host "Created group $localGroup"
    }

    # 3. Nest the department (global group) inside the permission (domain local group)
    Add-ADGroupMember -Identity $localGroup -Members $globalGroup

    # 4. Department folder with its own permissions (inheritance removed)
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
    icacls $folder /inheritance:r /grant:r `
        'SYSTEM:(OI)(CI)F' `
        'BUILTIN\Administrators:(OI)(CI)F' `
        "$NetBiosDomain\$($localGroup):(OI)(CI)M" | Out-Null
    Write-Host "Folder ready: $folder  ($localGroup = Modify)"
}

# 5. Share: broad share permissions, real control comes from NTFS.
#    Access-Based Enumeration hides folders a user can't open.
if (-not (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name $ShareName -Path $RootPath `
        -FullAccess "$NetBiosDomain\Domain Admins" `
        -ChangeAccess 'NT AUTHORITY\Authenticated Users' `
        -FolderEnumerationMode AccessBased | Out-Null
    Write-Host "Created share \\$env:COMPUTERNAME\$ShareName"
}
else {
    Set-SmbShare -Name $ShareName -FolderEnumerationMode AccessBased -Force
    Write-Host "Share \\$env:COMPUTERNAME\$ShareName already exists; Access-Based Enumeration enabled"
}

Write-Host ''
Get-SmbShare -Name $ShareName | Format-List Name, Path, FolderEnumerationMode | Out-String | Write-Host
