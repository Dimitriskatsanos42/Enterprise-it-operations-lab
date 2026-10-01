<#
.SYNOPSIS
    Εξάγει μια πλήρη αναφορά απογραφής χρηστών Active Directory, συμπεριλαμβανομένης
    κατάστασης λογαριασμού, συμμετοχών σε groups, και ηλικίας password - χρήσιμο για
    τριμηνιαίες επανεξετάσεις πρόσβασης και ελέγχους ανενεργών λογαριασμών.

.DESCRIPTION
    Παράγει ένα CSV με μία γραμμή ανά χρήστη AD που περιέχει: username, display name,
    τμήμα, κατάσταση ενεργός/ανενεργός, ημερομηνία τελευταίου logon, ημερομηνία τελευταίας
    αλλαγής password, και αν ο λογαριασμός είναι μέλος προνομιακού group (GG_IT_Admins).
    Επισημαίνει επίσης λογαριασμούς ανενεργούς για 60+ ημέρες.

.PARAMETER OutputPath
    Διαδρομή για την αναφορά CSV. Default: .\ad-users-report.csv

.PARAMETER InactiveDays
    Αριθμός ημερών χωρίς logon για να επισημανθεί λογαριασμός ως ανενεργός. Default 60.

.EXAMPLE
    .\Export-ADUsers.ps1 -InactiveDays 45
#>

[CmdletBinding()]
param(
    [string]$OutputPath = ".\ad-users-report.csv",
    [int]$InactiveDays = 60
)

Import-Module ActiveDirectory -ErrorAction Stop

$privilegedGroup = "GG_IT_Admins"
$privilegedMembers = (Get-ADGroupMember -Identity $privilegedGroup -Recursive | Select-Object -ExpandProperty SamAccountName)

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)

$users = Get-ADUser -Filter * -Properties DisplayName, Department, Enabled, LastLogonDate, PasswordLastSet, whenCreated

$report = foreach ($u in $users) {
    [pscustomobject]@{
        Username         = $u.SamAccountName
        DisplayName      = $u.DisplayName
        Department       = $u.Department
        Enabled          = $u.Enabled
        Created          = $u.whenCreated
        LastLogonDate    = $u.LastLogonDate
        PasswordLastSet  = $u.PasswordLastSet
        PasswordAgeDays  = if ($u.PasswordLastSet) { [math]::Round(((Get-Date) - $u.PasswordLastSet).TotalDays, 0) } else { "Δεν έχει οριστεί ποτέ" }
        IsPrivileged     = $privilegedMembers -contains $u.SamAccountName
        InactiveFlag     = if ($u.Enabled -and $u.LastLogonDate -and $u.LastLogonDate -lt $cutoffDate) { "ΝΑΙ - ανενεργός $InactiveDays+ ημέρες" }
                            elseif ($u.Enabled -and -not $u.LastLogonDate) { "ΝΑΙ - ποτέ δεν συνδέθηκε" }
                            else { "Όχι" }
    }
}

$report | Sort-Object Department, DisplayName | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Εξήχθησαν $($report.Count) εγγραφές χρηστών στο $OutputPath" -ForegroundColor Green

$inactive = $report | Where-Object { $_.InactiveFlag -like "ΝΑΙ*" }
if ($inactive) {
    Write-Warning "$($inactive.Count) ενεργός/οί λογαριασμός/οί επισημάνθηκαν ως ανενεργοί ($InactiveDays+ ημέρες) - προτείνεται επανεξέταση για απενεργοποίηση:"
    $inactive | Select-Object Username, DisplayName, Department, InactiveFlag | Format-Table -AutoSize
}
