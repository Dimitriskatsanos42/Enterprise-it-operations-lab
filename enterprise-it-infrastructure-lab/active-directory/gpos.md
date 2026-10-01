# Group Policy Objects (GPOs)

## Συνοπτικός Πίνακας

| Όνομα GPO | Συνδεδεμένο σε | Σκοπός |
|---|---|---|
| GPO-Domain-PasswordPolicy | Ρίζα Domain | Επιβολή πολυπλοκότητας/ιστορικού/lockout password για όλους τους χρήστες |
| GPO-Workstation-Hardening | Departments (OU Computers) | Firewall, απενεργοποίηση guest, απενεργοποίηση περιττών υπηρεσιών, screen lock |
| GPO-USB-Restriction | Departments (OU Computers), εκτός IT | Αποκλεισμός removable storage σε τυπικά endpoints |
| GPO-Windows-Update | Ρίζα Domain | Κεντρικοποιημένη ρύθμιση WSUS/Windows Update |
| GPO-IT-Admin-Rights | OU=IT,OU=Departments | Προσθέτει το GG_IT_Admins στο τοπικό Administrators μέσω Restricted Groups |
| GPO-Server-Hardening | OU=Servers | Baseline ασφάλειας ειδικό για servers (audit policy, hardening υπηρεσιών) |

---

## GPO-Domain-PasswordPolicy

| Ρύθμιση | Τιμή |
|---|---|
| Ελάχιστο μήκος password | 12 χαρακτήρες |
| Ιστορικό password | 10 προηγούμενα passwords απομνημονεύονται |
| Μέγιστη ηλικία password | 90 ημέρες |
| Ελάχιστη ηλικία password | 1 ημέρα |
| Απαιτήσεις πολυπλοκότητας | Ενεργές |
| Threshold lockout λογαριασμού | 5 λανθασμένες προσπάθειες |
| Διάρκεια lockout λογαριασμού | 30 λεπτά |
| Reset μετρητή lockout μετά από | 30 λεπτά |

**Διαδρομή:** Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies

---

## GPO-Workstation-Hardening

| Ρύθμιση | Τιμή |
|---|---|
| Λογαριασμός Guest | Απενεργοποιημένος |
| Windows Firewall (Domain profile) | Ενεργό, default deny εισερχόμενης κίνησης |
| Περιττές υπηρεσίες (Remote Registry, Telnet κ.λπ.) | Απενεργοποιημένες |
| Screen lock | 10 λεπτά αδράνειας, απαιτείται password στο resume |
| Τοπικός λογαριασμός Administrator | Μετονομασμένος, password διαχειρίζεται μέσω LAPS (σύσταση παραγωγικού περιβάλλοντος) |
| AutoPlay για removable media | Απενεργοποιημένο |

---

## GPO-USB-Restriction

| Ρύθμιση | Τιμή |
|---|---|
| Πρόσβαση Removable Storage | Deny all (Read/Write) |
| Εφαρμόζεται σε | Όλα τα OU τμημάτων εκτός IT |
| Σκεπτικό | Μείωση κινδύνου διαρροής δεδομένων σε τυπικά endpoints, ενώ το IT διατηρεί πρόσβαση σε storage για εργαλεία διάγνωσης/imaging |

---

## GPO-Windows-Update

| Ρύθμιση | Τιμή |
|---|---|
| Πηγή updates | Εσωτερικός server WSUS (ή Windows Update for Business σε παραγωγικό περιβάλλον) |
| Αυτόματα updates | Προγραμματισμένη εγκατάσταση, καθημερινά στις 03:00 |
| Συμπεριφορά επανεκκίνησης | Προγραμματισμένη επανεκκίνηση με ειδοποίηση χρήστη 15 λεπτών, αναβάλλεται αν ο χρήστης είναι ενεργός |
| Update rings | Το τμήμα IT λαμβάνει updates 3 ημέρες πριν από την ευρύτερη διάθεση (early ring) |

---

## GPO-IT-Admin-Rights

Χρησιμοποιεί **Restricted Groups** για να προσθέσει το `AEGEANTECH\GG_IT_Admins` στο τοπικό group `Administrators` σε όλα τα μηχανήματα του `OU=IT,OU=Departments`, ώστε το προσωπικό IT να έχει τοπικά δικαιώματα admin μόνο στο δικό του workstation — όχι δικαιώματα admin σε επίπεδο domain.

---

## GPO-Server-Hardening

| Ρύθμιση | Τιμή |
|---|---|
| Audit policy | Καταγράφονται events logon/logoff, διαχείρισης λογαριασμών, και πρόσβασης αντικειμένων |
| SMBv1 | Απενεργοποιημένο |
| Remote Desktop | Περιορισμένο μόνο σε GG_IT_Admins / πηγή VLAN 10 |
| Windows Firewall | Ενεργό, μόνο ρητοί κανόνες εισερχόμενης κίνησης για τις απαραίτητες υπηρεσίες |

---

## Δοκιμή & Rollback

Κάθε GPO δοκιμάζεται σε ένα μεμονωμένο πιλοτικό OU (`OU=Pilot`) πριν συνδεθεί ευρύτερα, και εκτελείται `gpresult /h report.html` σε ένα δοκιμαστικό μηχάνημα για επιβεβαίωση των εφαρμοσμένων ρυθμίσεων πριν την ευρύτερη εφαρμογή. Κάθε αλλαγή GPO καταγράφεται με ημερομηνία + περιγραφή αλλαγής σε αυτό το αρχείο, ώστε να διατηρείται ιστορικό ελέγχου.
