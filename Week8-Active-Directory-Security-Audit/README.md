# Week 8 - Active Directory Security Audit

My lab domain had a security setting that never locked an account, no matter how many wrong passwords were typed.
This week I learned to read what a domain controller logs, found that weakness, fixed it, and wrapped everything into a small audit script.

Screenshots for every step are in `week-08-ad-security-proofs.pdf` (machine names, account names and the domain name are redacted).

## Lab setup

- 1 Windows Server 2022 domain controller (Active Directory)
- 1 Windows 10 client joined to the domain
- Organizational units, test users and security groups created in Week 7

## What I did

### Day 1 - Reading logon events on the domain controller

A domain controller records authentication activity for the whole domain, not only for itself.

| Event ID | Meaning |
|----------|---------|
| 4624 | Successful logon |
| 4625 | Failed logon |
| 4776 | Credential validation (Error Code `0x0` = success) |

What I learned:

- Logon Type 5 is a service, not a person at a keyboard.
- An account name ending with `$` is a machine account. Computers log on to the domain on their own.
- In a 4625 event, the **Subject** block shows who *requested* the logon. The account that failed is in **Account For Which Logon Failed**.
- Sub Status `0xC000006A` = the user name exists but the password is wrong. `0xC0000064` = the user does not exist.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 5 |
    Select-Object TimeCreated, Id
```

### Day 2 - Password policy and account lockout

```powershell
Get-ADDefaultDomainPasswordPolicy
```

| Setting | Value found |
|---------|-------------|
| MinPasswordLength | 7 |
| ComplexityEnabled | True |
| MaxPasswordAge | 42 days |
| **LockoutThreshold** | **0** |
| LockoutDuration | 30 minutes |

`LockoutThreshold = 0` means accounts are **never** locked. An attacker can try unlimited passwords on any account (password guessing).

Fix: lock an account after 5 failed attempts.

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity <domain> -LockoutThreshold 5
```

Test: I typed a wrong password 5 times for a test account from the Windows 10 client. On the domain controller, Event **4740** (account locked out) recorded:

- **Account That Was Locked Out:** the test account
- **Caller Computer Name:** the Windows 10 client

The Subject block of a 4740 shows the domain controller's own machine account, not the locked account.

```powershell
Unlock-ADAccount -Identity <test-account>
```

### Day 3 - Privileged groups and Group Policy (GPO)

Who can do everything in the domain?

```powershell
Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name, SamAccountName
```

Result: a single member, the built-in `Administrator`. Least privilege is respected, but everything relies on one account. If its password is stolen, the whole domain is compromised, which is why the lockout policy matters.

A GPO is a rule written once on the domain controller and applied to every account of an OU.

- **Block-ControlPanel:** `User Configuration > Policies > Administrative Templates > Control Panel > Prohibit access to Control Panel and PC settings = Enabled`, linked to the Marketing OU. On the client, `control` returns a "Restrictions" message after `gpupdate /force`.
- **Block-CMD (done on my own):** `... > System > Prevent access to the command prompt = Enabled`. The option to also disable scripts was left on "No" so batch files still run.

Key points: the rule is stored on the domain controller but restricts the user's own workstation. It applies to every account in the linked OU, and accounts in other OUs are not affected.

### Day 4 - Mini-project: `audit-ad.ps1`

One script that runs a basic security audit of the domain, with four blocks:

1. Password policy
2. Domain Admins members
3. Disabled and locked-out accounts
4. Failed logons over the last 7 days

```powershell
# audit-ad.ps1 - Basic Active Directory security audit

Write-Host "=== 1. Password policy ===" -ForegroundColor Cyan
Get-ADDefaultDomainPasswordPolicy |
    Select-Object MinPasswordLength, ComplexityEnabled, MaxPasswordAge, LockoutThreshold, LockoutDuration

Write-Host "=== 2. Domain Admins members ===" -ForegroundColor Cyan
Get-ADGroupMember -Identity "Domain Admins" |
    Select-Object Name, SamAccountName

Write-Host "=== 3a. Disabled accounts ===" -ForegroundColor Cyan
Search-ADAccount -AccountDisabled -UsersOnly |
    Select-Object Name, SamAccountName

Write-Host "=== 3b. Locked-out accounts ===" -ForegroundColor Cyan
Search-ADAccount -LockedOut -UsersOnly |
    Select-Object Name, SamAccountName

Write-Host "=== 4. Failed logons (last 7 days) ===" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id
```

New command of the day: `Search-ADAccount` finds accounts in a given state (`-AccountDisabled`, `-LockedOut`). `-UsersOnly` leaves out machine accounts.

## Audit result

| Check | Result | Reading |
|-------|--------|---------|
| Password policy | Min length 7, complexity on, 42 days, lockout after 5 attempts / 30 min | Lockout now active (it was 0 before the fix) |
| Domain Admins | 1 member: `Administrator` | Least privilege respected |
| Disabled accounts | `krbtgt`, `Guest` | Both are built-in accounts, disabled by default |
| Locked-out accounts | None | Test accounts were unlocked |
| Failed logons (7 days) | 1 event (4625) | Low activity |

## Limits and next steps

- Block 4 shows only the time and event ID. It does not say which account failed or from where. Next version: extract the account name and source machine from each event.
- The audit has no threshold or alert. Next version: flag a weak lockout setting or an unexpected Domain Admins member automatically.
- The minimum password length of 7 is the default value. A longer minimum would be a reasonable hardening step.

## Key takeaways

- A domain controller logs authentication for the whole domain: 4624, 4625, 4776, 4740.
- Always read the right block of an event: Subject vs. the affected account.
- A default setting is not always a secure setting. Auditing is how you find out.
- GPOs enforce rules at scale from one place.

## Month 2 recap (Windows, PowerShell, Active Directory)

- **Week 5 - Windows fundamentals:** file system, PowerShell pipeline, permissions (icacls), persistence locations (services, Run keys, scheduled tasks), and a first audit script.
- **Week 6 - Windows security and logs:** firewall, listening ports, Event Viewer, event IDs 4624 / 4625 / 4720 / 4726, and a summary script.
- **Week 7 - Active Directory setup:** domain creation, OUs, users and groups, joining a Windows 10 client, and a provisioning script.
- **Week 8 - Active Directory security:** domain logs, password and lockout policy, privileged groups, GPOs, and an audit script.
