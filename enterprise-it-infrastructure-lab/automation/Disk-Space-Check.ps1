<#
.SYNOPSIS
    Ελέγχει τον χώρο δίσκου σε servers-στόχους και ειδοποιεί αν ο ελεύθερος χώρος πέσει
    κάτω από ένα ρυθμιζόμενο threshold. Σχεδιασμένο να τρέχει ως scheduled task στο MON01.

.DESCRIPTION
    Προορίζεται για ένα scheduled task (π.χ. κάθε 30 λεπτά) που ελέγχει όλους τους σταθερούς
    δίσκους στους καθορισμένους servers και:
      - Καταγράφει τα αποτελέσματα σε ένα ιστορικό CSV
      - Στέλνει email ειδοποίησης αν κάποιος δίσκος είναι κάτω από το threshold warning/critical
      - Γράφει στο Windows Event Log για κεντρική συλλογή logs

.PARAMETER ComputerName
    Servers προς έλεγχο. Default η βασική λίστα servers.

.PARAMETER WarningThresholdPct
    Ποσοστό ελεύθερου χώρου κάτω από το οποίο εμφανίζεται WARNING. Default 20%.

.PARAMETER CriticalThresholdPct
    Ποσοστό ελεύθερου χώρου κάτω από το οποίο εμφανίζεται ειδοποίηση CRITICAL. Default 10%.

.PARAMETER AlertEmail
    Διεύθυνση αποστολής email ειδοποίησης (απαιτεί ρυθμισμένο Send-MailMessage / SMTP relay).

.EXAMPLE
    .\Disk-Space-Check.ps1 -ComputerName DC01,SRV01,MON01 -AlertEmail it-alerts@aegeantech.local
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName = @("DC01", "SRV01", "MON01"),
    [int]$WarningThresholdPct  = 20,
    [int]$CriticalThresholdPct = 10,
    [string]$AlertEmail = "it-alerts@aegeantech.local",
    [string]$SmtpServer = "smtp.aegeantech.local",
    [string]$LogPath = ".\disk-space-history.csv"
)

$alerts = [System.Collections.Generic.List[string]]::new()
$results = [System.Collections.Generic.List[object]]::new()

foreach ($server in $ComputerName) {
    try {
        $disks = Get-CimInstance -ComputerName $server -ClassName Win32_LogicalDisk -Filter "DriveType=3"

        foreach ($disk in $disks) {
            $freePct = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)

            $status = "OK"
            if ($freePct -lt $CriticalThresholdPct) {
                $status = "CRITICAL"
                $alerts.Add("[CRITICAL] $server δίσκος $($disk.DeviceID) στο $freePct% ελεύθερο")
            }
            elseif ($freePct -lt $WarningThresholdPct) {
                $status = "WARNING"
                $alerts.Add("[WARNING] $server δίσκος $($disk.DeviceID) στο $freePct% ελεύθερο")
            }

            $results.Add([pscustomobject]@{
                Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Server      = $server
                Drive       = $disk.DeviceID
                SizeGB      = [math]::Round($disk.Size / 1GB, 1)
                FreeGB      = [math]::Round($disk.FreeSpace / 1GB, 1)
                FreePercent = $freePct
                Status      = $status
            })

            # Εγγραφή στο Windows Event Log για κεντρική παρακολούθηση
            if ($status -ne "OK") {
                Write-EventLog -LogName Application -Source "DiskSpaceMonitor" `
                    -EventId 5001 -EntryType Warning `
                    -Message "Ο δίσκος $($disk.DeviceID) στο $server είναι στο $freePct% ελεύθερο ($status)" `
                    -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        $alerts.Add("[ΣΦΑΛΜΑ] Αδυναμία ελέγχου $server : $($_.Exception.Message)")
    }
}

# Προσθήκη στο ιστορικό log
$results | Export-Csv -Path $LogPath -NoTypeInformation -Append

# Αποστολή email ειδοποίησης αν παραβιάστηκε κάποιο threshold
if ($alerts.Count -gt 0) {
    $body = $alerts -join "`n"
    Write-Warning $body

    try {
        Send-MailMessage -To $AlertEmail -From "monitoring@aegeantech.local" `
            -Subject "[AegeanTech] Ειδοποίηση Χώρου Δίσκου - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
            -Body $body -SmtpServer $SmtpServer -ErrorAction Stop
    }
    catch {
        Write-Warning "Δεν ήταν δυνατή η αποστολή email ειδοποίησης: $($_.Exception.Message)"
    }
}
else {
    Write-Host "Όλοι οι δίσκοι εντός φυσιολογικών ορίων." -ForegroundColor Green
}
