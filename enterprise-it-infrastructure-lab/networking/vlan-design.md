# Σχεδιασμός VLAN

## Πίνακας VLAN

| VLAN ID | Όνομα | Subnet | Σκοπός |
|---|---|---|---|
| 10 | Management | 192.168.10.0/24 | Workstations IT admin, διαχείριση υποδομής |
| 20 | Users | 192.168.20.0/24 | Endpoints εργαζομένων |
| 30 | Servers | 192.168.30.0/24 | Domain controller, file server, monitoring |
| 40 | Guest | 192.168.40.0/24 | Guest Wi-Fi, μόνο internet |

## Γιατί Χρειάζεται Segmentation;

Ένα flat δίκτυο σημαίνει ότι ένα compromised laptop εργαζομένου μπορεί να επικοινωνήσει απευθείας με τον domain controller σε οποιοδήποτε port. Το segmentation σε VLANs με κανόνες firewall μεταξύ τους σημαίνει ότι:

- Ένα compromised endpoint χρήστη (VLAN 20) μπορεί να φτάσει τους servers μόνο στα συγκεκριμένα ports που χρειάζεται (DNS, DHCP, Kerberos, SMB) — όχι RDP ή πρωτόκολλα διαχείρισης.
- Οι συσκευές guest (VLAN 40) δεν βλέπουν καθόλου εσωτερική κίνηση.
- Μόνο συσκευές του Management VLAN (10) μπορούν να διαχειριστούν απευθείας τους servers.

Αυτό είναι κλασικό defense-in-depth: ακόμη και χωρίς κάποιο breach, κρατά επίσης μικρότερα τα broadcast domains και κάνει το troubleshooting ευκολότερο (ξέρεις ακριβώς ποιος πρέπει να μιλάει με ποιον).

## Ρύθμιση Switch (παράδειγμα — Layer 3 switch ή router-on-a-stick)

```
! Ορισμός VLAN
vlan 10
 name Management
vlan 20
 name Users
vlan 30
 name Servers
vlan 40
 name Guest

! Trunk προς το firewall
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40

! Παράδειγμα access ports (VLAN χρηστών)
interface range GigabitEthernet0/2-24
 switchport mode access
 switchport access vlan 20
```

## Δρομολόγηση Μεταξύ VLAN

Η δρομολόγηση μεταξύ VLANs γίνεται από το firewall (που λειτουργεί ως default gateway για κάθε VLAN), το οποίο εφαρμόζει επίσης τα ACLs που περιγράφονται στο [`../architecture/network-diagram.md`](../architecture/network-diagram.md#κανόνες-ροής-κίνησης-firewall). Έτσι η δρομολόγηση και η πολιτική ασφάλειας μένουν σε ένα σημείο αντί να είναι διάσπαρτες σε πολλαπλές συσκευές.
