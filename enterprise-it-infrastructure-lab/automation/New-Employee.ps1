<#
.SYNOPSIS
    Δημιουργεί μαζικά λογαριασμούς χρηστών Active Directory από ένα αρχείο CSV,
    τους αναθέτει στο σωστό OU τμήματος και security group, και ενεργοποιεί τον λογαριασμό.

.DESCRIPTION
    Διαβάζει το active-directory/users.csv και, για κάθε γραμμή:
      1. Δημιουργεί τον χρήστη AD στο σωστό OU Department/Users
      2. Δημιουργεί ισχυρό προσωρινό password (ο χρήστης πρέπει να το αλλάξει στο πρώτο logon)
      3. Προσθέτει τον χρήστη στο αντίστοιχο security group τμήματος
      4. Ενεργοποιεί τον λογαριασμό
      5. Καταγράφει το αποτέλεσμα (επιτυχία/αποτυχία) σε αναφορά CSV

.PARAMETER CsvPath
    Διαδρομή προς το CSV εισόδου. Αναμενόμενες στήλες:
    FirstName,LastName,Username,Department,Title,Office,SecurityGroup

.EXAMPLE
    .\New-Employee.ps1 -CsvPath "..\active-directory\users.csv"

.NOTES
    Author: IT Support / AegeanTech Lab
    Απαιτεί: PowerShell module ActiveDirectory, εκτέλεση σε/κατά Domain Controller
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$Domain = "aegeantech.local",

    [string]$BaseOU = "OU=Departments,DC=aegeantech,DC=local",

    [switch]$WhatIfMode
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-RandomPassword {
    # Δημιουργεί password 16 χαρακτήρων που πληροί τις απαιτήσεις πολυπλοκότητας
    Add-Type -AssemblyName System.Web
    do {
        $pwd = [System.Web.Security.Membership]::GeneratePassword(16, 4)
    } until ($pwd -match '[A-Z]' -and $pwd -match '[a-z]' -and $pwd -match '[0-9]')
    return $pwd
}

if (-not (Test-Path $CsvPath)) {
    Write-Error "Το αρχείο CSV δεν βρέθηκε στη διαδρομή: $CsvPath"
    exit 1
}

$employees = Import-Csv -Path $CsvPath
$results   = [System.Collections.Generic.List[object]]::new()

foreach ($emp in $employees) {

    $displayName = "$($emp.FirstName) $($emp.LastName)"
    $ouPath      = "OU=Users,OU=$($emp.Department),$BaseOU"
    $upn         = "$($emp.Username)@$Domain"

    try {
        if (Get-ADUser -Filter "SamAccountName -eq '$($emp.Username)'" -ErrorAction SilentlyContinue) {
            Write-Warning "ΠΑΡΑΛΕΙΦΘΗΚΕ: Ο χρήστης $($emp.Username) υπάρχει ήδη."
            $results.Add([pscustomobject]@{
                Username = $emp.Username; DisplayName = $displayName
                Status = "Παραλείφθηκε (υπάρχει ήδη)"; Password = ""
            })
            continue
        }

        $password = New-RandomPassword
        $securePwd = ConvertTo-SecureString $password -AsPlainText -Force

        if ($WhatIfMode) {
            Write-Host "[WHATIF] Θα δημιουργούνταν ο χρήστης $($emp.Username) στο $ouPath"
        }
        else {
            New-ADUser `
                -Name $displayName `
                -GivenName $emp.FirstName `
                -Surname $emp.LastName `
                -SamAccountName $emp.Username `
                -UserPrincipalName $upn `
                -Path $ouPath `
                -Department $emp.Department `
                -Title $emp.Title `
                -Office $emp.Office `
                -AccountPassword $securePwd `
                -ChangePasswordAtLogon $true `
                -Enabled $true

            Add-ADGroupMember -Identity $emp.SecurityGroup -Members $emp.Username

            Write-Host "ΔΗΜΙΟΥΡΓΗΘΗΚΕ: $($emp.Username) ($displayName) -> $ouPath -> $($emp.SecurityGroup)" -ForegroundColor Green
        }

        $results.Add([pscustomobject]@{
            Username = $emp.Username; DisplayName = $displayName
            Status = "Δημιουργήθηκε"; Password = $password
        })
    }
    catch {
        Write-Warning "ΑΠΕΤΥΧΕ: $($emp.Username) - $($_.Exception.Message)"
        $results.Add([pscustomobject]@{
            Username = $emp.Username; DisplayName = $displayName
            Status = "Απέτυχε: $($_.Exception.Message)"; Password = ""
        })
    }
}

$reportPath = ".\New-Employee-Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "`nΟλοκληρώθηκε. Η αναφορά αποθηκεύτηκε στο $reportPath" -ForegroundColor Cyan
Write-Host "ΣΗΜΑΝΤΙΚΟ: Η αναφορά περιέχει προσωρινά passwords σε απλό κείμενο - αποθηκεύστε την με ασφάλεια και διαγράψτε την μετά τη διανομή στους χρήστες." -ForegroundColor Yellow
