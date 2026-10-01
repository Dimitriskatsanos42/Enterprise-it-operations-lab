# Σχεδιασμός Υποδομής

## Προφίλ Εταιρείας

| Πεδίο | Τιμή |
|---|---|
| Εταιρεία | AegeanTech Ltd. |
| Εργαζόμενοι | 40 |
| Τμήματα | Management, IT, Finance, HR, Sales |
| Domain (FQDN) | aegeantech.local |
| Όνομα NetBIOS | AEGEANTECH |
| Domain Controller | DC01 (192.168.30.10) |

## Στόχοι Σχεδιασμού

1. Κεντρικοποιημένη διαχείριση ταυτότητας και πρόσβασης μέσω Active Directory
2. Network segmentation για απομόνωση server traffic, management και end-user κίνησης
3. Αυτοματοποιημένος, επαναλήψιμος κύκλος ζωής χρηστών (onboarding/offboarding)
4. Baseline ασφάλειας που επιβάλλεται μέσω Group Policy, όχι με χειροκίνητη ρύθμιση
5. Τεκμηριωμένη διαδικασία backup και disaster recovery
6. Διαδικασία IT support που παράγει ελέγξιμα αρχεία (tickets)

## Λογικό Διάγραμμα

```
                         INTERNET
                            │
                       ┌────▼────┐
                       │ FIREWALL│
                       └────┬────┘
                            │
                     ┌──────▼──────┐
                     │    SWITCH   │  (802.1Q trunking)
                     └──────┬──────┘
                            │
          ┌─────────────────┼─────────────────┬──────────────┐
          │                 │                 │              │
     VLAN 10             VLAN 20          VLAN 30         VLAN 40
   Management            Users            Servers          Guest
   192.168.10.0/24     192.168.20.0/24   192.168.30.0/24  192.168.40.0/24
          │                 │                 │              │
     Admin PCs          Employee PCs     DC01 / SRV01 /   Guest Wi-Fi
                                          MON01            (απομονωμένο,
                                                            χωρίς πρόσβαση
                                                            στο domain)
```

## Σκεπτικό Σχεδιασμού

- **VLAN 10 (Management):** Μόνο workstations IT administrators. Μόνο αυτό το VLAN έχει πρόσβαση RDP/WinRM στους servers.
- **VLAN 20 (Users):** Τυπικά endpoints εργαζομένων. Λαμβάνουν IP μέσω DHCP, είναι domain-joined, χωρίς άμεση πρόσβαση σε console servers.
- **VLAN 30 (Servers):** Στατικές IP, domain controller και file/monitoring servers. Οι κανόνες firewall περιορίζουν την εισερχόμενη κίνηση μόνο στα απαραίτητα ports (DNS 53, DHCP 67/68, LDAP 389, Kerberos 88, SMB 445, RDP 3389 μόνο από το VLAN 10).
- **VLAN 40 (Guest):** Πλήρως απομονωμένο από τα εσωτερικά VLANs, πρόσβαση μόνο στο internet, χωρίς εμπιστοσύνη προς το domain.

## Servers

| Server | Ρόλος | IP | Σημειώσεις |
|---|---|---|---|
| DC01 | AD DS, DNS, DHCP | 192.168.30.10 | Κύριος domain controller |
| SRV01 | File Server | 192.168.30.20 | Shares τμημάτων (Finance, HR, Sales, IT, Management) |
| MON01 | Monitoring | 192.168.30.30 | Διαθεσιμότητα & παρακολούθηση πόρων |

Δες [`ip-addressing.md`](ip-addressing.md) για το πλήρες πλάνο IP και [`network-diagram.md`](network-diagram.md) για πιο αναλυτικό διάγραμμα δικτύου.
