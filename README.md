# Enterprise IT Infrastructure Lab — AegeanTech Ltd.

## 📌 Επισκόπηση

Αυτό το repository τεκμηριώνει τον σχεδιασμό και την υλοποίηση ενός **προσομοιωμένου εταιρικού IT περιβάλλοντος** για μια φανταστική εταιρεία 40 εργαζομένων, την **AegeanTech Ltd.** Δημιουργήθηκε ως hands-on lab για να αποδείξει πρακτικές, ρεαλιστικές δεξιότητες IT administration και IT support — αυτές που χρειάζεται καθημερινά ένας Junior IT Support ή System Administrator.

**Σενάριο:**
> Η AegeanTech Ltd. είναι μια εταιρεία 40 χρηστών, χωρισμένη σε 5 τμήματα (Management, IT, Finance, HR, Sales). Η εταιρεία χρειάζεται κεντρικοποιημένη διαχείριση ταυτοτήτων, αυτοματοποιημένο onboarding/offboarding χρηστών, auditing endpoints, ασφάλεια μέσω Group Policy, υπηρεσίες DNS/DHCP, μια λειτουργική διαδικασία IT support, στρατηγική backup, και βασικό monitoring — όλα τεκμηριωμένα σε επαγγελματικό επίπεδο.

Το project καλύπτει ολόκληρο τον κύκλο ζωής μιας εταιρικής IT υποδομής: **σχεδιασμός → υλοποίηση → automation → support → ασφάλεια → backup → τεκμηρίωση.**

---

## 🏗️ Αρχιτεκτονική

```
                         INTERNET
                            │
                       ┌────▼────┐
                       │ FIREWALL│
                       └────┬────┘
                            │
                     ┌──────▼──────┐
                     │    SWITCH   │
                     └──────┬──────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
     VLAN 10             VLAN 20          VLAN 30
   Management            Users            Servers
          │                 │                 │
     Admin PCs          Employee PCs     ┌───────┐
                                         │ DC01  │
                                         │ DNS   │
                                         │ DHCP  │
                                         └───────┘
```

Πλήρεις λεπτομέρειες: [`architecture/infrastructure.md`](architecture/infrastructure.md)

---

## 🗂️ Δομή Repository

| Φάκελος | Περιεχόμενο |
|---|---|
| [`architecture/`](architecture) | Διάγραμμα δικτύου, σχεδιασμός υποδομής, IP addressing plan |
| [`active-directory/`](active-directory) | Λίστα χρηστών, δομή OU, security groups, GPOs |
| [`networking/`](networking) | Σχεδιασμός VLAN, DNS, DHCP, firewall rules |
| [`automation/`](automation) | PowerShell scripts για onboarding, offboarding, auditing, monitoring |
| [`it-support/`](it-support) | Παραδείγματα tickets, knowledge base, troubleshooting guides |
| [`security/`](security) | Baseline ασφάλειας, least privilege, audit policy |
| [`backup/`](backup) | Στρατηγική backup και disaster recovery plan |
| [`docs/`](docs) | SOPs για onboarding/offboarding, γενικός οδηγός troubleshooting |
| [`screenshots/`](screenshots) | Screenshots από το lab (AD, GPO, DNS, DHCP consoles κ.λπ.) |

---

## 🧩 Τι Αποδεικνύει Αυτό το Project

- **Active Directory** — σχεδιασμός OU, security groups, μαζική δημιουργία χρηστών από CSV με PowerShell
- **Group Policy** — password policy, hardening workstations, περιορισμός USB, διαχείριση Windows Update
- **Networking** — segmentation με VLAN, DNS zones, DHCP scopes, firewall rules
- **PowerShell Automation** — onboarding/offboarding, auditing υπολογιστών, έλεγχοι disk space & service health
- **Διαδικασία IT Support** — ρεαλιστικός κύκλος ζωής ticket με root cause analysis
- **Ασφάλεια** — least privilege, account lockout policy, hardening baseline, audit policy
- **Backup & Disaster Recovery** — πρόγραμμα backup και πλήρες DR runbook για αστοχία domain controller
- **Τεκμηρίωση** — SOPs γραμμένα όπως θα τα περίμενε ένας IT Manager

---

## 🛠️ Τεχνολογίες που Χρησιμοποιήθηκαν

- Windows Server 2022 (AD DS, DNS, DHCP)
- Windows 11 (client endpoints)
- Group Policy Management
- PowerShell 5.1 / 7
- VirtualBox / VMware Workstation / Hyper-V (virtualization για το lab)
- Git / GitHub
- (Σχεδιασμένο) Microsoft 365 / Entra ID hybrid identity
- (Σχεδιασμένο) Zabbix / βασικό monitoring

---

## 🖥️ Lab Environment

| VM | Ρόλος | IP | Specs |
|---|---|---|---|
| DC01 | AD DS + DNS + DHCP | 192.168.30.10 | Win Server 2022, 4GB RAM, 2 vCPU, 60GB |
| SRV01 | File Server | 192.168.30.20 | Win Server 2022, 4GB RAM, 2 vCPU, 60GB |
| MON01 | Monitoring | 192.168.30.30 | Win Server 2022 / Linux, 2GB RAM |
| CLIENT01 | Test endpoint HR/Finance | DHCP (VLAN 20) | Win 11, 4GB RAM |
| CLIENT02 | Test endpoint IT/Sales | DHCP (VLAN 20) | Win 11, 4GB RAM |

Πλήρες πλάνο VLAN/IP: [`architecture/ip-addressing.md`](architecture/ip-addressing.md)

---

## 📸 Screenshots

Δες τον φάκελο [`screenshots/`](screenshots) — Active Directory Users and Computers, GPO settings, DNS zones, DHCP scopes, output από PowerShell scripts κ.λπ. *(Πρόσθεσε δικά σου screenshots καθώς χτίζεις το lab.)*

---

## 🚀 Πώς Χτίστηκε

1. Σχεδιασμός domain, network segmentation και δομής τμημάτων
2. Ανάπτυξη virtual lab (VirtualBox/VMware/Hyper-V)
3. Εγκατάσταση και ρύθμιση AD DS, DNS, DHCP στο DC01
4. Μαζική δημιουργία χρηστών και ομάδων από CSV μέσω PowerShell
5. Δημιουργία και σύνδεση Group Policy Objects
6. Συγγραφή PowerShell scripts automation για κοινές εργασίες IT admin
7. Προσομοίωση ρεαλιστικών tickets IT support και επίλυσή τους
8. Τεκμηρίωση security hardening, στρατηγικής backup, και DR plan
9. Συγγραφή αυτής της τεκμηρίωσης σε επαγγελματικό επίπεδο

---

## 📬 Σχετικά με το Project

Αυτό είναι ένα προσωπικό lab project που φτιάχτηκε για να αποδείξει πρακτικές δεξιότητες IT Support / System Administration για αιτήσεις εργασίας. Όλα τα ονόματα εταιρειών, χρηστών και δεδομένα είναι φανταστικά.
