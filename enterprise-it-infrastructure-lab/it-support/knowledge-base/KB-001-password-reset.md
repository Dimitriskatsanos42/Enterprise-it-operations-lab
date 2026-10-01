# KB-001 — Reset Password Χρήστη στο Domain

**Κατηγορία:** Διαχείριση Λογαριασμών
**Κοινό:** IT Support L1

## Πότε Χρησιμοποιείται

Ο χρήστης έχει ξεχάσει το password του, ή απαιτείται reset password ως μέρος του onboarding ή απόκρισης ασφάλειας.

## Βήματα

1. Επαληθεύστε την ταυτότητα του αιτούντος σύμφωνα με το [`../troubleshooting/identity-verification.md`](../troubleshooting/identity-verification.md) — **ποτέ μην κάνετε reset password βάσει μόνο ενός αιτήματος email/chat.**
2. Ανοίξτε το **Active Directory Users and Computers** (ή χρησιμοποιήστε το PowerShell παρακάτω).
3. Κάντε reset το password σε προσωρινή τιμή και επιβάλετε αλλαγή στο επόμενο logon:

```powershell
Set-ADAccountPassword -Identity <username> -Reset `
    -NewPassword (ConvertTo-SecureString "TempPass!2026" -AsPlainText -Force)

Set-ADUser -Identity <username> -ChangePasswordAtLogon $true
```

4. Αν ο λογαριασμός είναι επίσης κλειδωμένος, ξεκλειδώστε τον:

```powershell
Unlock-ADAccount -Identity <username>
```

5. Επικοινωνήστε το προσωρινό password στον χρήστη μέσω ασφαλούς καναλιού (τηλεφωνική κλήση ή αυτοπροσώπως — ποτέ μέσω απλού email).
6. Επιβεβαιώστε ότι ο χρήστης μπορεί να συνδεθεί και του ζητείται να ορίσει νέο password.
7. Κλείστε το ticket σημειώνοντας ότι έγινε το reset και επαληθεύτηκε η ταυτότητα.

## Συχνά Λάθη

- Η παράλειψη του `-ChangePasswordAtLogon $true` αφήνει το προσωρινό password ενεργό επ' αόριστον.
- Το reset password **δεν** αίρει αυτόματα το lockout του λογαριασμού — συνήθως χρειάζονται και τα δύο βήματα μαζί.
- Αν ο χρήστης λέει ότι το reset "δεν δούλεψε", ελέγξτε αν εισάγει το password σε cached/offline συσκευή που δεν έχει ακόμη φτάσει στο DC (δείτε KB-002).

## Σχετικά

- [KB-002 — Διάγνωση Επαναλαμβανόμενων Lockouts Λογαριασμού](KB-002-account-lockouts.md)
- [Ticket INC-003](../tickets/INC-003.md) — πραγματικό παράδειγμα lockout που προκλήθηκε από cached διαπιστευτήρια
