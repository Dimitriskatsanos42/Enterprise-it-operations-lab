# Security Groups

## Κανόνας Ονοματολογίας

`GG_<Σκοπός>` — Global Group, με στόχο ένα μοναδικό σκοπό (πρόσβαση τμήματος ή ρόλος). Κρατιέται απλό και flat για μια εταιρεία 40 χρηστών· ένας μεγαλύτερος οργανισμός θα πρόσθετε domain local groups για πρόσβαση σε resources (μοντέλο AGDLP).

## Groups Τμημάτων

| Group | Τύπος | Μέλη | Σκοπός |
|---|---|---|---|
| GG_Management | Global Security | Τμήμα Management | Πρόσβαση στον κοινόχρηστο φάκελο Management |
| GG_IT_Admins | Global Security | Τμήμα IT | Αυξημένα δικαιώματα, πρόσβαση σε servers, admin tools |
| GG_Finance | Global Security | Τμήμα Finance | Πρόσβαση στον κοινόχρηστο φάκελο Finance |
| GG_HR | Global Security | Τμήμα HR | Πρόσβαση στον κοινόχρηστο φάκελο HR |
| GG_Sales | Global Security | Τμήμα Sales | Πρόσβαση στον κοινόχρηστο φάκελο Sales |

## Groups Ρόλου / Λειτουργίας

| Group | Σκοπός |
|---|---|
| GG_VPN_Users | Μέλη με δικαίωμα σύνδεσης μέσω VPN |
| GG_Remote_Desktop_Users | Μέλη με δικαίωμα RDP πρόσβασης σε συγκεκριμένα endpoints |
| GG_Printer_ColorPrinting | Πρόσβαση στην ουρά έγχρωμου εκτυπωτή |
| GG_Helpdesk_L1 | Προσωπικό υποστήριξης πρώτης γραμμής — δικαιώματα reset password & unlock account, ανατεθειμένα μέσω delegation στο AD |

## Μοντέλο Δικαιωμάτων

- Τα **shares τμημάτων** (`\\SRV01\Finance$`, `\\SRV01\HR$` κ.λπ.) παραχωρούν δικαιώματα NTFS + Share μόνο στο αντίστοιχο group `GG_<Τμήμα>` — ποτέ απευθείας σε μεμονωμένους χρήστες.
- Το **GG_IT_Admins** προστίθεται στο τοπικό group Administrators σε client μηχανήματα μέσω GPO Restricted Groups, όχι σε επίπεδο domain, για περιορισμό της έκτασης ζημιάς σε περίπτωση compromise.
- Επανεξέταση προσβάσεων: οι υπεύθυνοι τμημάτων εξετάζουν τη συμμετοχή στα groups κάθε τρίμηνο (δες [`security/least-privilege.md`](../security/least-privilege.md)).

## PowerShell: Δημιουργία των Groups

```powershell
$groups = @(
    "GG_Management","GG_IT_Admins","GG_Finance","GG_HR","GG_Sales",
    "GG_VPN_Users","GG_Remote_Desktop_Users","GG_Helpdesk_L1"
)

foreach ($g in $groups) {
    New-ADGroup -Name $g -GroupScope Global -GroupCategory Security `
        -Path "OU=Departments,DC=aegeantech,DC=local"
}
```

Δες [`../automation/New-Employee.ps1`](../automation/New-Employee.ps1) για το πώς οι χρήστες προστίθενται αυτόματα στο σωστό group με βάση το τμήμα τους κατά τη δημιουργία.
