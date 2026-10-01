# Αντιμετώπιση Προβλημάτων: Ο Υπολογιστής Δεν Μπορεί να Συνδεθεί στο Domain

## Σύμπτωμα

Η προσπάθεια σύνδεσης ενός Windows client στο `aegeantech.local` αποτυγχάνει με σφάλμα όπως "An Active Directory Domain Controller could not be contacted" ή "The specified domain either does not exist or could not be contacted."

## Βήματα Διάγνωσης

1. **Έλεγχος συνδεσιμότητας δικτύου προς τον DC**
   ```powershell
   Test-Connection dc01.aegeantech.local
   Test-NetConnection dc01.aegeantech.local -Port 389   # LDAP
   Test-NetConnection dc01.aegeantech.local -Port 88    # Kerberos
   ```
   Αν αυτά αποτύχουν, το πρόβλημα είναι δικτύου/firewall (π.χ. ο client είναι σε λάθος VLAN ή κάποιος κανόνας firewall μπλοκάρει την κίνηση VLAN 20 → VLAN 30 στα ports 88/389/445).

2. **Έλεγχος ανάλυσης DNS**
   ```powershell
   Resolve-DnsName aegeantech.local
   Resolve-DnsName dc01.aegeantech.local
   ```
   Ο DNS server του client (μέσω DHCP option 006) πρέπει να δείχνει στο `192.168.30.10`. Αν δείχνει σε δημόσιο DNS server του ISP αντ' αυτού, η αναζήτηση domain θα αποτυγχάνει πάντα. Ελέγξτε με `ipconfig /all`.

3. **Επαλήθευση συγχρονισμού ώρας**
   Η ταυτοποίηση Kerberos αποτυγχάνει αν τα ρολόγια client και DC διαφέρουν πάνω από 5 λεπτά.
   ```powershell
   w32tm /query /status
   ```
   Τα domain-joined μηχανήματα συγχρονίζουν την ώρα από τον DC αυτόματα· ένα μηχάνημα που δεν έχει ενταχθεί ποτέ πρέπει να συγχρονίζεται από την ίδια πηγή NTP που είναι ρυθμισμένη στο firewall.

4. **Επιβεβαίωση ότι δεν υπάρχει ήδη ο λογαριασμός υπολογιστή με αντικρουόμενο όνομα**
   Ελέγξτε το AD Users and Computers, ή:
   ```powershell
   Get-ADComputer -Filter "Name -eq '<hostname>'"
   ```
   Αν υπάρχει παλιό αντικείμενο (π.χ. reimaged μηχάνημα, ίδιο όνομα, διαφορετικός λογαριασμός), διαγράψτε το παλιό αντικείμενο ή κάντε reset πριν την επανασύνδεση.

5. **Επιβεβαίωση ότι ο λογαριασμός έχει δικαιώματα σύνδεσης στο domain**
   Από προεπιλογή αυτό απαιτεί είτε δικαιώματα Domain Admin είτε ανατεθειμένη άδεια "join a computer to the domain" (ανατεθειμένη στο `GG_IT_Admins` σε αυτό το περιβάλλον).

## Παράδειγμα Επίλυσης

Πιο συχνή βασική αιτία σε αυτό το περιβάλλον: ο DNS server που ανατέθηκε στον client μέσω DHCP παρέμενε ρυθμισμένος στο default του router (π.χ. `192.168.20.1`) αντί για `192.168.30.10`, επειδή η επιλογή scope DHCP είχε ρυθμιστεί λάθος μετά από ανακατασκευή του scope. Διορθώθηκε διορθώνοντας το DHCP option 006 (δες [`../../networking/dhcp.md`](../../networking/dhcp.md)) και εκτελώντας `ipconfig /release` / `ipconfig /renew` στον client.
