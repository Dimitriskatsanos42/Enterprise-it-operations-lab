# Ρύθμιση DHCP

## Server

Ο ρόλος DHCP είναι εγκατεστημένος στο **DC01** (192.168.30.10). Σε ένα μεγαλύτερο περιβάλλον αυτό θα χωριζόταν ή θα γινόταν clustered (DHCP failover), αλλά για μια εταιρεία 40 χρηστών ένας μοναδικός authoritative server με τεκμηριωμένη διαδικασία ανάκτησης (δες [`../backup/disaster-recovery.md`](../backup/disaster-recovery.md)) είναι επαρκής.

## Scopes

### Scope: Users (VLAN 20)

| Ρύθμιση | Τιμή |
|---|---|
| Όνομα scope | AEGEANTECH-Users |
| Subnet | 192.168.20.0/24 |
| Εύρος | 192.168.20.100 – 192.168.20.200 |
| Διάρκεια lease | 8 ημέρες |
| Router (option 003) | 192.168.20.1 |
| DNS servers (option 006) | 192.168.30.10 |
| Όνομα domain DNS (option 015) | aegeantech.local |

### Scope: Guest (VLAN 40)

| Ρύθμιση | Τιμή |
|---|---|
| Όνομα scope | AEGEANTECH-Guest |
| Subnet | 192.168.40.0/24 |
| Εύρος | 192.168.40.50 – 192.168.40.250 |
| Διάρκεια lease | 4 ώρες |
| Router (option 003) | 192.168.40.1 |
| DNS servers (option 006) | 1.1.1.1, 8.8.8.8 |

## Reservations

Οι εκτυπωτές και οι κοινόχρηστες συσκευές παίρνουν DHCP reservations (αντί για στατικές IP ρυθμισμένες τοπικά) ώστε να παραμένουν κεντρικά διαχειρίσιμες και ορατές στην κονσόλα DHCP.

| Συσκευή | Διεύθυνση MAC | Δεσμευμένη IP |
|---|---|---|
| Εκτυπωτής γραφείου (όροφος Finance) | AA:BB:CC:00:01:01 | 192.168.20.50 |
| Εκτυπωτής γραφείου (όροφος Sales) | AA:BB:CC:00:01:02 | 192.168.20.51 |

## Εξουσιοδότηση

Ο DHCP server του DC01 είναι εξουσιοδοτημένος στο Active Directory (`Authorize-DhcpServer`), κάτι που αποτρέπει την εμπιστοσύνη προς μη εξουσιοδοτημένους/rogue DHCP servers από άλλους domain-joined DHCP servers και βοηθά στον εντοπισμό εσφαλμένα ρυθμισμένων συσκευών που εκδίδουν leases.

## PowerShell: Ρύθμιση Scope

```powershell
Add-DhcpServerV4Scope -Name "AEGEANTECH-Users" `
    -StartRange 192.168.20.100 -EndRange 192.168.20.200 `
    -SubnetMask 255.255.255.0 -State Active

Set-DhcpServerV4OptionValue -ScopeId 192.168.20.0 `
    -Router 192.168.20.1 -DnsServer 192.168.30.10 -DnsDomain "aegeantech.local"
```

## Παρακολούθηση

Η χρήση του scope DHCP ελέγχεται εβδομαδιαία (`Get-DhcpServerv4ScopeStatistics`) για να εντοπίζεται εξάντληση leases πριν προκαλέσει αδυναμία νέων συσκευών να λάβουν διεύθυνση.
