# Week 7 – Days 3 & 4: Organizing an Active Directory Domain and Joining a Client

Part of my 6-month cybersecurity roadmap. After creating the domain `cyber-lab.local` (Days 1–2), I organized it, then joined a Windows 10 machine to it.

📄 [Full report with all screenshots (PDF)](https://github.com/user-attachments/files/34152382/Week7_Days3-4_Active_Directory.pdf) – IPv6 addresses and machine names are masked, no password appears anywhere, and all users are fictional.

## Lab

| Machine | OS | Role |
|---|---|---|
| Server | Windows Server 2022 | Domain controller for `cyber-lab.local` (static IP `192.168.1.200`) |
| Client | Windows 10 Pro | Machine to join to the domain (DHCP) |

---

## Day 3 – Organizing the domain

### 1. Organizational units (OUs)

An OU is a folder inside the directory. A fresh domain only has the built-in `Domain Controllers` OU, so I created one per department.

```powershell
Get-ADOrganizationalUnit -Filter * | Select-Object Name
New-ADOrganizationalUnit -Name "Marketing" -Path "DC=cyber-lab,DC=local"
New-ADOrganizationalUnit -Name "Logistics" -Path "DC=cyber-lab,DC=local"
New-ADOrganizationalUnit -Name "IT" -Path "DC=cyber-lab,DC=local"
```

### 2. Reading an address in the directory

Every object has a full address, read from right to left:

```text
CN=Mohamed Ali,OU=Marketing,DC=cyber-lab,DC=local
```

- `DC=cyber-lab,DC=local`: the domain
- `OU=Marketing`: the OU where the object is stored
- `CN=Mohamed Ali`: the object's own name

This is what goes after `-Path` when creating something inside an OU.

### 3. Users: created disabled

```powershell
New-ADUser -Name "Mohamed Ali" -SamAccountName "mohamed.ali" -Path "OU=Marketing,DC=cyber-lab,DC=local"
Get-ADUser -Identity mohamed.ali | Select-Object Name, SamAccountName, Enabled, DistinguishedName | Format-List
```

`Enabled` was `False`. Enabling the account failed:

```text
Enable-ADAccount : The password does not meet the length, complexity, or history requirement of the domain.
```

The account had no valid password. Fix: set one first, then enable.

```powershell
Set-ADAccountPassword -Identity mohamed.ali -Reset
Enable-ADAccount -Identity mohamed.ali
```

`-Reset` sets a password without knowing the old one, and PowerShell prompts for it, so it never appears in the command.

### 4. Security groups

```powershell
New-ADGroup -Name "Marketing-team" -GroupScope Global -GroupCategory Security -Path "OU=Marketing,DC=cyber-lab,DC=local"
Add-ADGroupMember -Identity "Marketing-team" -Members mohamed.ali
Get-ADGroupMember -Identity "Marketing-team" | Select-Object Name, SamAccountName
```

### 5. OU or group?

- **OU**: a container. It answers "where is this object stored?"
- **Group**: a list of members. It answers "who gets which rights?"

A user has one OU but can be in many groups.

### 6. Exercise

Repeated the same steps for Logistics and IT: one fictional user and one security group per department, all verified with `Get-ADGroupMember`.

---

## Day 4 – Joining a Windows 10 client

### 1. The problem: the PC cannot find the domain

```powershell
ping cyber-lab.local
```

Result: "could not find host". No packet was even sent, because the name was never translated. That points to **DNS**, not the firewall.

### 2. Pointing the PC at my server's DNS

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.200
```

The ping still failed. `Get-NetIPConfiguration` showed my server at the bottom of the DNS list, below two IPv6 entries from the router.

### 3. Splitting the problem in two

```powershell
nslookup cyber-lab.local 192.168.1.200
Resolve-DnsName cyber-lab.local
```

- `nslookup` asks my server directly, skipping the DNS list: it answered correctly. **The server is fine.**
- `Resolve-DnsName` follows the DNS list like `ping` does: "The DNS name does not exist". **Another DNS in the list answered first.**

`ipconfig /flushdns` changed nothing.

### 4. A one-character typo

```powershell
# Fails: ObjectNotFound (dash instead of underscore)
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms-tcpip6
# Works
Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6
```

After disabling IPv6 on the card, the only DNS left was my server, and `ping cyber-lab.local` replied. I did not formally prove why, but removing the router's DNS entries made it work. This is a **lab workaround**, not a production recommendation.

### 5. Joining the domain

Windows 10 Pro can join a domain (a Home edition cannot). Before the join:

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Domain, PartOfDomain | Format-List
# Domain: WORKGROUP, PartOfDomain: False
```

```powershell
Add-Computer -DomainName "cyber-lab.local" -Credential (Get-Credential) -Restart
```

The domain asks for the credentials of an account allowed to add machines. `Get-Credential` opens a prompt, so no password is typed in the command.

### 6. Verification

After the restart I signed in with a domain account:

```powershell
whoami
# cyber-lab\mohamed.ali
Get-CimInstance Win32_ComputerSystem | Select-Object Domain, PartOfDomain | Format-List
# Domain: cyber-lab.local, PartOfDomain: True
```

### 7. Two accounts were still disabled

Checking all three accounts showed `Enabled : False` for two of them. They had been created disabled and I never enabled them.

```powershell
Enable-ADAccount -Identity jean.paul
Enable-ADAccount -Identity omar.talib
```

After that, `jean.paul` signed in on a PC where he has no local account: his account was created once, on the server.

### 8. Where does the PC live in the directory?

```powershell
Get-ADComputer -Filter * | Select-Object Name, DistinguishedName | Format-List
```

The Windows 10 PC sits in the default `CN=Computers` container, not in one of my OUs.

---

## What I learned

- A new account stays disabled until it has a valid password.
- OU: where an object lives. Group: who gets which rights.
- "Could not find host" means DNS first.
- Split the problem: `nslookup` tested the server, `Resolve-DnsName` tested the PC.
- Verify the final state (can the person sign in?), not only that the object exists.

## Next

Move the computer into an OU, then the Week 7 mini-project.
