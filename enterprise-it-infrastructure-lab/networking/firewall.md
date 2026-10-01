# Κανόνες Firewall

## Perimeter Firewall (Internet ↔ Εσωτερικό δίκτυο)

| Κανόνας # | Πηγή | Προορισμός | Port/Πρωτόκολλο | Ενέργεια | Σκοπός |
|---|---|---|---|---|---|
| 1 | Οποιαδήποτε | WAN interface | Οποιαδήποτε εισερχόμενη | Deny | Default deny εισερχόμενης κίνησης από internet |
| 2 | Εσωτερικά VLANs | Internet | 443/tcp, 80/tcp | Allow | Πλοήγηση web / updates |
| 3 | Εσωτερικά VLANs | Internet | 123/udp | Allow | Συγχρονισμός ώρας NTP |
| 4 | DC01 | Internet | 443/tcp | Allow | Windows Update / ενεργοποίηση άδειας |

## Κανόνες Μεταξύ VLAN

| Κανόνας # | Πηγή VLAN | Προορισμός VLAN | Port/Πρωτόκολλο | Ενέργεια | Σκοπός |
|---|---|---|---|---|---|
| 10 | VLAN 20 (Users) | VLAN 30 (Servers) | 53 tcp/udp | Allow | DNS |
| 11 | VLAN 20 (Users) | VLAN 30 (Servers) | 67/68 udp | Allow | DHCP |
| 12 | VLAN 20 (Users) | VLAN 30 (Servers) | 88 tcp/udp | Allow | Kerberos auth |
| 13 | VLAN 20 (Users) | VLAN 30 (Servers) | 389 tcp | Allow | LDAP |
| 14 | VLAN 20 (Users) | VLAN 30 (Servers) | 445 tcp | Allow | SMB (file shares, GPO) |
| 15 | VLAN 20 (Users) | VLAN 30 (Servers) | Οτιδήποτε άλλο | Deny | Αποκλεισμός όλων των υπολοίπων by default |
| 20 | VLAN 10 (Mgmt) | VLAN 30 (Servers) | 3389 tcp | Allow | RDP για διαχείριση |
| 21 | VLAN 10 (Mgmt) | VLAN 30 (Servers) | 5985/5986 tcp | Allow | WinRM / PowerShell remoting |
| 30 | VLAN 20 (Users) | VLAN 10 (Mgmt) | Οποιοδήποτε | Deny | Οι χρήστες δεν έχουν πρόσβαση στα admin workstations |
| 40 | VLAN 40 (Guest) | VLAN 10/20/30 | Οποιοδήποτε | Deny | Το guest δίκτυο είναι πλήρως απομονωμένο |
| 41 | VLAN 40 (Guest) | Internet | 80/443 tcp | Allow | Πρόσβαση μόνο internet για guests |

## Καταγραφή (Logging)

Η απορριφθείσα κίνηση σε κανόνες με προορισμό servers (VLAN 30) καταγράφεται και ελέγχεται εβδομαδιαία — αυτό είναι συνήθως το πρώτο σημείο όπου εμφανίζονται προσπάθειες lateral movement ή εσφαλμένα ρυθμισμένες συσκευές.

## Έλεγχος Αλλαγών (Change Control)

Οι αλλαγές στους κανόνες firewall τεκμηριώνονται εδώ με ημερομηνία και αίτημα πριν εφαρμοστούν, ώστε το σύνολο κανόνων να παραμένει ελέγξιμο αντί να συσσωρεύει μη τεκμηριωμένες εξαιρέσεις με τον καιρό.
