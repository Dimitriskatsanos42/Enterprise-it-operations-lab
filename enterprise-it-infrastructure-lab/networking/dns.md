# Ρύθμιση DNS

## Επισκόπηση

Το DC01 τρέχει την AD-integrated ζώνη DNS για το `aegeantech.local`, η οποία αναπαράγεται αυτόματα σε τυχόν επιπλέον domain controllers μέσω AD replication (χωρίς ανάγκη χειροκίνητου zone transfer).

## Ζώνες

| Ζώνη | Τύπος | Σημειώσεις |
|---|---|---|
| aegeantech.local | AD-Integrated Primary | Forward lookup zone, δυναμικές ενημερώσεις: μόνο Secure |
| 30.168.192.in-addr.arpa | AD-Integrated Primary | Reverse lookup για το VLAN Servers |
| 20.168.192.in-addr.arpa | AD-Integrated Primary | Reverse lookup για το VLAN Users |

## Forwarders

Τα εξωτερικά queries στέλνονται σε upstream DNS forwarders (π.χ. `1.1.1.1`, `8.8.8.8`) αντί να επιτρέπονται queries root hints απευθείας από τον εσωτερικό DNS server — πιο γρήγορη ανάλυση ονομάτων και ένα λιγότερο πράγμα εκτεθειμένο στο internet.

## Βασικά Records

| Record | Τύπος | Τιμή | Σκοπός |
|---|---|---|---|
| dc01.aegeantech.local | A | 192.168.30.10 | Domain controller |
| srv01.aegeantech.local | A | 192.168.30.20 | File server |
| mon01.aegeantech.local | A | 192.168.30.30 | Monitoring server |
| _ldap._tcp.aegeantech.local | SRV | (αυτόματο, DC locator) | Δημιουργείται αυτόματα από το AD DS |
| _kerberos._tcp.aegeantech.local | SRV | (αυτόματο, DC locator) | Δημιουργείται αυτόματα από το AD DS |

## Ρύθμιση Clients

Όλοι οι domain-joined clients λαμβάνουν DNS server `192.168.30.10` μέσω DHCP option 006. Κανένας client δεν είναι ρυθμισμένος να χρησιμοποιεί απευθείας εξωτερικό DNS — το εσωτερικό DNS προωθεί υπό όρους τα εξωτερικά queries, κάτι που διατηρεί συνεπή την ανάλυση split-horizon και επιτρέπει τα εσωτερικά ονόματα hosts να επιλύονται πάντα πρώτα.

## Σημειώσεις Ασφάλειας

- Οι δυναμικές ενημερώσεις ορίζονται σε **μόνο Secure** για αποτροπή εισαγωγής μη εξουσιοδοτημένων records.
- Τα zone transfers περιορίζονται μόνο σε εσωτερικούς DNS servers (κανένα προς το παρόν, μοναδικό DC στο lab).
- Ενεργοποιημένο DNS scavenging (7 ημέρες no-refresh / 7 ημέρες refresh interval) για καθαρισμό παλιών records από αποσυρμένα μηχανήματα.

## PowerShell: Έλεγχος Υγείας DNS

```powershell
# Έλεγχος αν ο DNS server απαντά
Resolve-DnsName dc01.aegeantech.local

# Επιβεβαίωση ύπαρξης SRV records για AD (πρέπει να επιστρέψει LDAP/Kerberos records)
Resolve-DnsName -Type SRV _ldap._tcp.aegeantech.local

# Εκτέλεση built-in διαγνωστικών DNS
dcdiag /test:dns
```
