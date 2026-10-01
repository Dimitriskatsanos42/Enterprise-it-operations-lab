<#
.SYNOPSIS
    Επαληθεύει ότι κρίσιμες υπηρεσίες Windows τρέχουν στους βασικούς servers υποδομής,
    και προσπαθεί αυτόματη επανεκκίνηση πριν ειδοποιήσει.

.DESCRIPTION
    Ελέγχει μια προκαθορισμένη λίστα κρίσιμων υπηρεσιών ανά ρόλο server (AD DS, DNS,
    DHCP στο DC01· file services στο SRV01 κ.λπ.). Αν μια υπηρεσία είναι σταματημένη,
    προσπαθεί να την ξεκινήσει μία φορά, και μετά καταγράφει αν το self-heal δούλεψε.
    Αυτή είναι η αυτοματοποιημένη διόρθωση πρώτης γραμμής που κάνει ένα σύστημα
    monitoring πριν κάνει escalation σε άνθρωπο.

.EXAMPLE
    .\Service-Health-Check.ps1
#>

[CmdletBinding()]
param(
    [string]$LogPath = ".\service-health-log.csv"
)

# Χαρτογράφηση servers με τις κρίσιμες υπηρεσίες που αναμένεται να τρέχουν σε αυτούς
$serviceMap = @{
    "DC01"  = @("NTDS", "DNS", "DHCPServer", "Netlogon", "KDC")
    "SRV01" = @("LanmanServer", "Spooler")
    "MON01" = @("Winmgmt")
}

$results = [System.Collections.Generic.List[object]]::new()

foreach ($server in $serviceMap.Keys) {
    foreach ($svcName in $serviceMap[$server]) {
        try {
            $svc = Get-Service -ComputerName $server -Name $svcName -ErrorAction Stop

            $action = "Καμία"
            if ($svc.Status -ne "Running") {
                Write-Warning "$server : Το $svcName είναι $($svc.Status) - γίνεται προσπάθεια επανεκκίνησης..."
                try {
                    Get-Service -ComputerName $server -Name $svcName | Start-Service -ErrorAction Stop
                    Start-Sleep -Seconds 5
                    $svc.Refresh()
                    $action = if ($svc.Status -eq "Running") { "Επανεκκινήθηκε αυτόματα με επιτυχία" } else { "Έγινε προσπάθεια επανεκκίνησης - δεν τρέχει ακόμη, χρειάζεται χειροκίνητη προσοχή" }
                }
                catch {
                    $action = "Η επανεκκίνηση ΑΠΕΤΥΧΕ: $($_.Exception.Message)"
                }
            }

            $results.Add([pscustomobject]@{
                Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Server      = $server
                Service     = $svcName
                StatusFound = $svc.Status
                Action      = $action
            })
        }
        catch {
            $results.Add([pscustomobject]@{
                Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Server      = $server
                Service     = $svcName
                StatusFound = "ΜΗ ΠΡΟΣΒΑΣΙΜΟ"
                Action      = "Αδυναμία ερωτήματος στον server: $($_.Exception.Message)"
            })
        }
    }
}

$results | Export-Csv -Path $LogPath -NoTypeInformation -Append

$problems = $results | Where-Object { $_.StatusFound -ne "Running" -and $_.Action -notlike "Επανεκκινήθηκε αυτόματα*" }
if ($problems) {
    Write-Warning "Οι παρακάτω υπηρεσίες χρειάζονται χειροκίνητη προσοχή:"
    $problems | Format-Table -AutoSize
}
else {
    Write-Host "Όλες οι παρακολουθούμενες υπηρεσίες είναι υγιείς (ή αυτό-ανακτήθηκαν)." -ForegroundColor Green
}
