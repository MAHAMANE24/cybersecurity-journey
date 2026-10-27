# Week 7 – Days 1 & 2: Building an Active Directory Domain Controller

Part of my 6-month cybersecurity roadmap. This write-up covers the first two days of Week 7: preparing the network, then creating my first Active Directory domain in a home lab.

📄 **Full report with screenshots (PDF)** [Week7_Days1-2_Active_Directory.pdf](https://github.com/user-attachments/files/34003850/Week7_Days1-2_Active_Directory.pdf)
 – the report is written in French. Sensitive details (IPv6 address, machine name) are masked on every screenshot, and no password appears anywhere.

## Lab setup

| Machine | OS | Role |
|---|---|---|
| VM 1 | Windows Server 2022 | Future domain controller |
| VM 2 | Windows 10 | Future domain member |

Both VMs run in VirtualBox with **bridged networking**, so each one gets an address from my home router, like a real computer on the network.

## Goal

Understand **why** Active Directory exists, then build it step by step:

- A local account only exists on one machine. In a company with many computers, creating the same account everywhere does not scale.
- Active Directory is a **central directory**: accounts are created once, and machines ask the directory who may log in.
- The server that holds this directory is called a **domain controller**.

---

## Day 1 – Network foundations

### 1. Ping fails between the two VMs

**Symptom:** pinging the server from Windows 10 returns `Request timed out`, with 100% packet loss.

**Diagnosis, step by step:**

1. Checked that both VMs are on the same network (`ipconfig`): same first three numbers (`192.168.1.x`) and same gateway. So the network itself is fine.
2. A "timed out" means the packet leaves but nothing comes back. The most likely cause is a firewall dropping the echo request.
3. Checked the built-in firewall rule that allows ping:

```powershell
Get-NetFirewallRule -Name "FPS-ICMP4-ERQ-In" | Select-Object DisplayName, Enabled, Direction, Action, Profile
```

My first attempt had a typo (`Enables` instead of `Enabled`). PowerShell did not show an error, it just left the column empty. An empty column can mean a misspelled property name.

Result after the fix: `Enabled : False`. The rule exists (Inbound, Allow) but is switched off.

**Fix:**

```powershell
Enable-NetFirewallRule -Name "FPS-ICMP4-ERQ-In"
```

After enabling it on the server, `Enabled` showed `True` and Windows 10 → server worked: 4 packets sent, 4 received, 0% loss.

### 2. Ping worked in one direction only

Server → Windows 10 still failed.

**Why:** each machine has its **own** firewall. I had only enabled the rule on the server. On the Windows 10 machine the same rule was still `Enabled : False`. After enabling it there too, ping worked in both directions.

### 3. Why the server needs a static IP

After a reboot, the IPs of my machines had changed. The router had handed out new ones through **DHCP**.

A domain controller cannot move around: other machines must always find it at the same address. So it needs a **static IP**.

**Before choosing the address, I checked that it was free:**

```powershell
ping 192.168.1.200
```

The replies came from my own machine saying `Destination host unreachable`, so nobody used `192.168.1.200`.

### 4. Lesson about reading ping output

- `Request timed out`: the packet left, nobody answered.
- `Destination host unreachable` with a reply coming from **my own IP**: the machine could not find anyone at that address.
- In the second case, the statistics can show `Received = 4, Lost = 0 (0% loss)`. These "replies" are error messages from my own machine. I learned to read **who sends the reply**, not just the summary line.

### 5. Switching to a static configuration

```powershell
# Stop asking the router for an address
Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Disabled

# Set the address and the gateway
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.200 -PrefixLength 24 -DefaultGateway 192.168.1.1

# Set the DNS server (the router, for now)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.1.1
```

Right after disabling DHCP, the card showed a `169.254.x.x` address and no gateway. That is Windows' fallback address when it has no configuration, and it is expected until the static address is set.

**Verification:** `ping google.com` returned replies. This tests two things at once: DNS (the name was translated into an IP) and the gateway (the packet reached the Internet).

### 6. A clear hostname

The default name (`WIN-` followed by random characters) is unreadable and hard to change once the server becomes a domain controller. Windows computer names must be 15 characters or fewer, with letters, digits and hyphens only (no spaces, no `_`, no `@`).

```powershell
Rename-Computer -NewName "<server-name>" -Restart
```

After the reboot, `hostname` showed the new name and the static IP was still in place.

---

## Day 2 – Creating the domain

### 1. Installing a role is not the same as creating the domain

Installing the **AD DS role** only puts the software on the server. The directory does not exist yet. A second step, the **promotion**, creates the domain and turns the server into a domain controller.

### 2. Install the AD DS role

```powershell
Get-WindowsFeature -Name AD-Domain-Services      # before: [ ]
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Get-WindowsFeature -Name AD-Domain-Services      # after: [X]
```

`-IncludeManagementTools` installs the tools I will use later to manage the directory.

### 3. Choosing the domain name

- Two parts separated by a dot.
- The first part is limited to 15 characters (Windows also uses it as the short domain name).
- No `@`, no spaces, no accents.
- It names the lab, not the role. `AD-Domain-Services` is the role, not a company name.

I chose `cyber-lab.local`. The `.local` ending shows that it only exists inside my private network.

### 4. The recovery password (DSRM)

The promotion asks for a **Directory Services Restore Mode** password. It is the emergency key used to repair the directory if it breaks. It must be strong, different from the normal administrator password, and **stored safely**: if it is lost, the directory cannot be repaired this way.

### 5. Promote the server

```powershell
Install-ADDSForest -DomainName "cyber-lab.local" -InstallDns
```

- A **forest** is the top-level container of one or more domains. Mine contains only one.
- `-InstallDns` installs DNS on the server, which a domain needs so that machines can find the domain controller by name.
- Yellow warnings about DNS delegation are expected in a lab.
- The server restarts by itself. The screen can stay black for several minutes, so I did not force a power-off.

### 6. Verification

The login screen now shows `CYBER-LAB\Administrator`: the account belongs to the domain instead of the local machine.

I also asked the directory itself:

```powershell
Get-ADDomain | Select-Object Name, DNSRoot, Forest | Format-List
```

```text
Name    : cyber-lab
DNSRoot : cyber-lab.local
Forest  : cyber-lab.local
```

### 7. What the promotion changed

- The DNS role is installed (`[X]`).
- The server's DNS entry is now `::1` and `127.0.0.1`. These addresses mean "myself": the server now uses itself as its DNS server. Before, it pointed to the router (`192.168.1.1`).

---

## What I learned

- Each machine has its own firewall, so a ping can work in one direction only.
- A ping result must be read carefully: who sends the reply matters more than the summary line.
- A domain controller needs a stable identity first: static IP, clear name, working DNS.
- Installing a role and promoting the server are two different steps.
- I verified each step with a command instead of assuming it worked.

## Screenshots

All screenshots (firewall rule before and after, static IP configuration, role installation, promotion, login screen and `Get-ADDomain` result) are in the [PDF report](Semaine7_Jours1-2_Active_Directory.pdf).

## Next

Day 3: organize the domain with organizational units, users and groups.
