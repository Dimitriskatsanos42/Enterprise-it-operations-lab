# Δομή Organizational Unit (OU)

## Αρχή Σχεδιασμού

Τα OUs είναι δομημένα ανά **τμήμα**, όχι ανά τύπο αντικειμένου, καθώς το Group Policy σε αυτό το περιβάλλον εφαρμόζεται ανά τμήμα (διαφορετικές πολιτικές password/workstation θα μπορούσαν να εφαρμοστούν στο Finance σε σχέση με το Sales, για παράδειγμα). Οι υπολογιστές τοποθετούνται στα OU τμημάτων μαζί με τους κύριους χρήστες τους για να απλοποιείται ο στόχος GPO· ένα ξεχωριστό OU Servers κρατά τα GPOs servers απομονωμένα από τα GPOs clients.

## Δομή

```
aegeantech.local
│
├── OU=Departments
│   ├── OU=Management
│   │   ├── OU=Users
│   │   └── OU=Computers
│   ├── OU=IT
│   │   ├── OU=Users
│   │   └── OU=Computers
│   ├── OU=Finance
│   │   ├── OU=Users
│   │   └── OU=Computers
│   ├── OU=HR
│   │   ├── OU=Users
│   │   └── OU=Computers
│   └── OU=Sales
│       ├── OU=Users
│       └── OU=Computers
│
├── OU=Servers
│   └── (DC01, SRV01, MON01 παραμένουν στο Domain Controllers / ξεχωριστό OU Servers)
│
├── OU=Admin
│   └── (Λογαριασμοί προνομίων/admin, ξεχωριστά από τους κανονικούς λογαριασμούς χρηστών)
│
└── OU=Service Accounts
    └── (Μη-interactive λογαριασμοί που χρησιμοποιούνται από υπηρεσίες/scripts)
```

## Σκεπτικό

| Απόφαση | Λόγος |
|---|---|
| OUs βασισμένα σε τμήματα | Ταιριάζει με το πώς πραγματικά ανατίθενται τα GPOs και τα δικαιώματα σε αυτή την εταιρεία |
| Διαχωρισμός Users/Computers ανά τμήμα | Επιτρέπει τα GPOs πλευράς χρήστη (password, desktop policy) και πλευράς υπολογιστή (firewall, BitLocker) να συνδέονται ανεξάρτητα |
| Ξεχωριστό OU Admin | Οι λογαριασμοί προνομίων παίρνουν αυστηρότερα GPOs (π.χ. χωρίς πλοήγηση internet, υποχρεωτικό smartcard/MFA σε παραγωγικό περιβάλλον) και εξαιρούνται από τις πολιτικές τυπικών χρηστών |
| Ξεχωριστό OU Service Accounts | Αποτρέπει τους service accounts από να επηρεάζονται από πολιτικές interactive-user (π.χ. screen lock, λήξη password διαχειρίζεται ξεχωριστά) |
| Οι Servers έξω από τα Departments | Τα GPOs servers (hardening, audit policy) είναι θεμελιωδώς διαφορετικά από τα GPOs clients και δεν πρέπει να επικαλύπτονται |

## PowerShell: Δημιουργία της Δομής OU

```powershell
$domain = "DC=aegeantech,DC=local"
$departments = "Management","IT","Finance","HR","Sales"

New-ADOrganizationalUnit -Name "Departments" -Path $domain
foreach ($dept in $departments) {
    New-ADOrganizationalUnit -Name $dept -Path "OU=Departments,$domain"
    New-ADOrganizationalUnit -Name "Users" -Path "OU=$dept,OU=Departments,$domain"
    New-ADOrganizationalUnit -Name "Computers" -Path "OU=$dept,OU=Departments,$domain"
}

New-ADOrganizationalUnit -Name "Admin" -Path $domain
New-ADOrganizationalUnit -Name "Service Accounts" -Path $domain
```
