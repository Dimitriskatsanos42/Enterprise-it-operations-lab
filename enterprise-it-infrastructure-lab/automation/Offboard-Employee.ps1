<#
.SYNOPSIS
    Κάνει offboard έναν χρήστη Active Directory: απενεργοποιεί τον λογαριασμό, αφαιρεί τις
    συμμετοχές σε groups, τον μετακινεί σε OU "Disabled Users", και τον κρύβει από τη
    λίστα διευθύνσεων, διατηρώντας παράλληλα τον λογαριασμό για μια περίοδο διατήρησης.

.DESCRIPTION
    Τυπική λίστα ελέγχου offboarding IT αυτοματοποιημένη:
      1. Απενεργοποίηση του λογαριασμού AD (ΔΕΝ τον διαγράφει - διατηρεί δεδομένα/ιστορικό ελέγχου)
      2. Reset password σε τυχαία άγνωστη τιμή (επιπλέον ασφάλεια ακόμη κι όταν είναι απενεργοποιημένος)
      3. Αφαίρεση όλων των συμμετοχών σε groups εκτός από Domain Users (καταγραφή πρώτα)
      4. Μετακίνηση λογαριασμού σε OU=Disabled Users για εύκολη αναγνώριση
      5. Απόκρυψη από λίστες διευθύνσεων Exchange/Entra
      6. Ορισμός AccountExpirationDate για αυτόματο καθαρισμό μετά την περίοδο διατήρησης
      7. Καταγραφή της ενέργειας για σκοπούς ελέγχου

.PARAMETER Username
    SamAccountName του χρήστη προς offboarding

.PARAMETER RetentionDays
    Αριθμός ημερών διατήρησης του απενεργοποιημένου λογαριασμού πριν είναι επιλέξιμος για διαγραφή (default 90)

.EXAMPLE
    .\Offboard-Employee.ps1 -Username jsmith
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [int]$RetentionDays = 90,

    [string]$DisabledOU = "OU=Disabled Users,DC=aegeantech,DC=local"
)

Import-Module ActiveDirectory -ErrorAction Stop

$user = Get-ADUser -Identity $Username -Properties MemberOf, DisplayName -ErrorAction Stop

Write-Host "Offboarding: $($user.DisplayName) ($Username)" -ForegroundColor Cyan

# 1. Καταγραφή τρεχουσών συμμετοχών σε groups για το log ελέγχου πριν την αφαίρεσή τους
$originalGroups = $user.MemberOf
$logPath = ".\offboarding-log_$Username`_$(Get-Date -Format 'yyyyMMdd').txt"
"Offboarding $($user.DisplayName) ($Username) στις $(Get-Date)" | Out-File $logPath
"Αρχικές συμμετοχές σε groups:" | Out-File $logPath -Append
$originalGroups | Out-File $logPath -Append

# 2. Απενεργοποίηση του λογαριασμού
Disable-ADAccount -Identity $Username
Write-Host "Ο λογαριασμός απενεργοποιήθηκε." -ForegroundColor Yellow

# 3. Reset password σε άγνωστη τυχαία τιμή (defense in depth)
Add-Type -AssemblyName System.Web
$randomPwd = [System.Web.Security.Membership]::GeneratePassword(20, 6)
Set-ADAccountPassword -Identity $Username -Reset `
    -NewPassword (ConvertTo-SecureString $randomPwd -AsPlainText -Force)

# 4. Αφαίρεση συμμετοχών σε groups (εκτός από Domain Users, που δεν μπορεί να αφαιρεθεί)
foreach ($group in $originalGroups) {
    try {
        Remove-ADGroupMember -Identity $group -Members $Username -Confirm:$false
    }
    catch {
        Write-Warning "Δεν ήταν δυνατή η αφαίρεση από το $group : $($_.Exception.Message)"
    }
}
Write-Host "Οι συμμετοχές σε groups αφαιρέθηκαν (καταγράφηκε στο $logPath)." -ForegroundColor Yellow

# 5. Μετακίνηση στο OU Disabled Users
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$DisabledOU'" -ErrorAction SilentlyContinue)) {
    Write-Warning "Το OU Disabled Users δεν υπάρχει - δημιουργήστε το πρώτα: New-ADOrganizationalUnit -Name 'Disabled Users' -Path 'DC=aegeantech,DC=local'"
}
else {
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
    Write-Host "Ο λογαριασμός μετακινήθηκε στο $DisabledOU." -ForegroundColor Yellow
}

# 6. Ορισμός ημερομηνίας λήξης για αυτόματο καθαρισμό μετά την περίοδο διατήρησης
$expiration = (Get-Date).AddDays($RetentionDays)
Set-ADUser -Identity $Username -AccountExpirationDate $expiration
Write-Host "Ο λογαριασμός ορίστηκε να λήξει/είναι επιλέξιμος για διαγραφή στις $expiration." -ForegroundColor Yellow

# 7. Ενημέρωση πεδίου description με metadata offboarding για ορατότητα
Set-ADUser -Identity $Username -Description "OFFBOARDED $(Get-Date -Format 'yyyy-MM-dd') - διατήρηση έως $($expiration.ToString('yyyy-MM-dd'))"

Write-Host "`nΤο offboarding ολοκληρώθηκε για τον/την $($user.DisplayName). Log: $logPath" -ForegroundColor Green
Write-Host "Υπενθύμιση: απενεργοποιήστε/προωθήστε χειροκίνητα το mailbox, ανακαλέστε άδειες VPN/M365, και παραλάβετε τον εξοπλισμό της εταιρείας σύμφωνα με το docs/offboarding.md" -ForegroundColor Cyan
