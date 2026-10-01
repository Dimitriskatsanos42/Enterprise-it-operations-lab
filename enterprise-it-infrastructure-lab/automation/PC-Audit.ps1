<#
.SYNOPSIS
    Κάνει audit έναν ή περισσότερους υπολογιστές (τοπικά ή domain-joined) και εξάγει μια
    αναφορά απογραφής hardware/OS σε CSV.

.DESCRIPTION
    Συλλέγει: Όνομα Υπολογιστή, OS, CPU, RAM, μέγεθος δίσκου/ελεύθερο χώρο, διεύθυνση IP,
    διεύθυνση MAC, τελευταία εκκίνηση, και έκδοση/build Windows για κάθε υπολογιστή-στόχο,
    και γράφει τα αποτελέσματα στο computer-audit.csv.

.PARAMETER ComputerName
    Ένας ή περισσότεροι υπολογιστές προς audit. Αν δεν οριστεί, χρησιμοποιεί όλους τους
    ενεργοποιημένους υπολογιστές που βρέθηκαν στο Active Directory (απαιτεί module AD).

.PARAMETER OutputPath
    Διαδρομή για την αναφορά CSV. Default: .\computer-audit.csv

.EXAMPLE
    .\PC-Audit.ps1 -ComputerName CLIENT01,CLIENT02

.EXAMPLE
    .\PC-Audit.ps1
    # Κάνει audit σε κάθε ενεργοποιημένο αντικείμενο υπολογιστή στο AD
#>

[CmdletBinding()]
param(
    [string[]]$ComputerName,
    [string]$OutputPath = ".\computer-audit.csv"
)

if (-not $ComputerName) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $ComputerName = (Get-ADComputer -Filter { Enabled -eq $true }).Name
        Write-Host "Δεν δόθηκε -ComputerName - γίνεται audit σε όλους τους $($ComputerName.Count) ενεργοποιημένους υπολογιστές AD." -ForegroundColor Cyan
    }
    catch {
        Write-Error "Δεν δόθηκε -ComputerName και το module ActiveDirectory δεν είναι διαθέσιμο. Ορίστε ρητά τους υπολογιστές."
        exit 1
    }
}

$report = [System.Collections.Generic.List[object]]::new()

foreach ($pc in $ComputerName) {

    Write-Host "Γίνεται audit στο $pc ..." -ForegroundColor Cyan

    if (-not (Test-Connection -ComputerName $pc -Count 1 -Quiet)) {
        Write-Warning "Το $pc δεν είναι προσβάσιμο - παραλείπεται."
        $report.Add([pscustomobject]@{
            ComputerName = $pc; Status = "Μη προσβάσιμο"
        })
        continue
    }

    try {
        $os     = Get-CimInstance -ComputerName $pc -ClassName Win32_OperatingSystem
        $cpu    = Get-CimInstance -ComputerName $pc -ClassName Win32_Processor | Select-Object -First 1
        $cs     = Get-CimInstance -ComputerName $pc -ClassName Win32_ComputerSystem
        $disk   = Get-CimInstance -ComputerName $pc -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
        $nic    = Get-CimInstance -ComputerName $pc -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Object -First 1
        $boot   = $os.LastBootUpTime

        $report.Add([pscustomobject]@{
            ComputerName   = $pc
            Status         = "OK"
            OS             = $os.Caption
            WindowsVersion = $os.Version
            CPU            = $cpu.Name
            RAM_GB         = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            DiskSize_GB    = [math]::Round($disk.Size / 1GB, 1)
            DiskFree_GB    = [math]::Round($disk.FreeSpace / 1GB, 1)
            DiskFreePct    = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
            IPAddress      = ($nic.IPAddress -join ", ")
            MACAddress     = $nic.MACAddress
            LastBoot       = $boot
            UptimeDays     = [math]::Round(((Get-Date) - $boot).TotalDays, 1)
        })
    }
    catch {
        Write-Warning "Αποτυχία audit στο $pc : $($_.Exception.Message)"
        $report.Add([pscustomobject]@{
            ComputerName = $pc; Status = "Σφάλμα: $($_.Exception.Message)"
        })
    }
}

$report | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "`nΤο audit ολοκληρώθηκε. Επεξεργάστηκαν $($report.Count) υπολογιστές. Αναφορά: $OutputPath" -ForegroundColor Green

# Επισήμανση μηχανημάτων με χαμηλό χώρο δίσκου για γρήγορη εξέταση
$lowDisk = $report | Where-Object { $_.DiskFreePct -ne $null -and $_.DiskFreePct -lt 15 }
if ($lowDisk) {
    Write-Warning "Τα παρακάτω μηχανήματα έχουν κάτω από 15% ελεύθερο χώρο δίσκου:"
    $lowDisk | Select-Object ComputerName, DiskFreePct | Format-Table -AutoSize
}
