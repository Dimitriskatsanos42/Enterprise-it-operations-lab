# Διάγραμμα Δικτύου

## Mermaid Diagram

Το GitHub εμφανίζει Mermaid diagrams απευθείας μέσα στο Markdown — αυτό θα εμφανιστεί σαν πραγματικό διάγραμμα στη σελίδα του repository.

```mermaid
flowchart TD
    INET[Internet] --> FW[Firewall]
    FW --> SW[Core Switch - 802.1Q Trunk]

    SW --> V10[VLAN 10 - Management<br/>192.168.10.0/24]
    SW --> V20[VLAN 20 - Users<br/>192.168.20.0/24]
    SW --> V30[VLAN 30 - Servers<br/>192.168.30.0/24]
    SW --> V40[VLAN 40 - Guest<br/>192.168.40.0/24]

    V10 --> ADMIN[Admin PCs]
    V20 --> EMP[Employee PCs]
    V40 --> GUEST[Guest Wi-Fi]

    V30 --> DC01[DC01<br/>AD DS / DNS / DHCP<br/>192.168.30.10]
    V30 --> SRV01[SRV01<br/>File Server<br/>192.168.30.20]
    V30 --> MON01[MON01<br/>Monitoring<br/>192.168.30.30]
```

## Κανόνες Ροής Κίνησης (Firewall)

| Πηγή | Προορισμός | Επιτρεπόμενα Ports | Σημειώσεις |
|---|---|---|---|
| VLAN 20 (Users) | VLAN 30 (Servers) | 53, 67/68, 88, 389, 445 | Μόνο DNS, DHCP, Kerberos, SMB |
| VLAN 10 (Mgmt) | VLAN 30 (Servers) | 3389, 5985/5986 | RDP + WinRM για διαχείριση |
| VLAN 20 (Users) | VLAN 10 (Mgmt) | Deny all | Οι χρήστες δεν έχουν πρόσβαση στα admin workstations |
| VLAN 40 (Guest) | VLAN 10/20/30 | Deny all | Το guest δίκτυο είναι πλήρως απομονωμένο |
| VLAN 40 (Guest) | Internet | 80, 443 | Πρόσβαση μόνο στο internet για guests |
| Όλα τα VLANs | Internet | 80, 443, 123 | Web + NTP |

## Σημείωση Φυσικού vs Λογικού Δικτύου

Στο lab, όλα τα VM τρέχουν σε ένα μοναδικό hypervisor host χρησιμοποιώντας internal/host-only δίκτυα ανά VLAN, με το firewall VM (π.χ. pfSense/OPNsense ή Windows RRAS) να δρομολογεί και να φιλτράρει την κίνηση μεταξύ τους. Αυτό αναπαριστά τον τρόπο με τον οποίο ένα φυσικό switch + firewall θα διαχώριζε την κίνηση σε παραγωγικό περιβάλλον.
