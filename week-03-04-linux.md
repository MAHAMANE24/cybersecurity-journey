## 1. Authentication Analysis

**Method:** `sudo journalctl | grep sshd`

I reviewed SSH activity on my Kali VM over the past 24 hours.

**Timeline:**
- **Oct 1, 10:44** — SSH service started (`Server listening on 0.0.0.0 port 22`), as expected on VM boot.
- **Oct 1, 10:53–10:54** — Successful login from `127.0.0.1` (local loopback test, same machine connecting to itself).
- **Oct 1, 10:55–11:19** — Successful login from `192.168.1.x` (a separate device on the local network, connecting via SSH client). Session lasted about 24 minutes.
- **Oct 1, ~12:08–12:09** — Failed login attempt with username `qwert`, which does not exist on this system (`Invalid user`, `user unknown`). The connection timed out before further attempts.
- **Oct 1, 12:16** — Failed login attempt using a valid username (`kali`) with an incorrect password (`Failed password for kali`).
- **Oct 2, 11:23** — SSH service restarted on VM boot.

**Observation:** the logs clearly distinguish two types of failed logins — an unknown username (`Invalid user`) versus a valid username with a wrong password (`Failed password`). This distinction could, in theory, let an attacker confirm which usernames exist on a system by observing which response they get.

**Conclusion:** all successful logins came from expected, known sources (localhost and my own physical machine). The two failed attempts were my own deliberate tests, not external attacks. No suspicious authentication activity was found.

## 2. Process Analysis

**Objective:** identify what is actually running on the machine, and whether any process stands out in terms of resource usage.

**Method:** `ps aux | sort -rnk 3 | grep -v "ps aux" | head -n 10`

The first attempt at this command gave misleading results: the pipeline's own components (`ps aux`, `sort`, `head`) appeared at the top of their own output, with artificially high CPU values. This happens because `ps aux` captures a snapshot of running processes at the exact moment it runs — including the very commands piped alongside it, which are starting up at that same instant. Filtering them out with `grep -v` was necessary to get a meaningful reading.

### Top processes (cleaned output)

| %CPU | User | Process | Role |
|---|---|---|---|
| 11.2 | root | kernel-related process (network/netfilter) | Internal kernel component |
| 4.1 | root | `/usr/lib/apt/methods/http` | Part of an ongoing `apt` package update |
| 3.2 | root | `[ksoftirqd/1]` | Kernel thread handling hardware interrupts on CPU core 1 |
| 3.2 | kali | CPU Graph widget | Desktop panel widget displaying CPU load |
| 3.0 | kali | `/usr/bin/qterminal` | The terminal application itself |

**Conclusion:** no unexpected or unfamiliar process was found. CPU usage was dominated by expected system components and an active package update, not by any suspicious activity. This also reinforced an important investigative lesson: **the tool you use to observe a system can itself distort what you observe** — a reminder to always sanity-check unexpected results before drawing conclusions.

## 3. Network Analysis

**Objective:** determine the machine's external attack surface — which network services are exposed and reachable.

**Method:** `sudo ss -tulnp`

| Port | Protocol | Service | Scope |
|---|---|---|---|
| 22 | TCP | SSH (`sshd`) | Listening on `0.0.0.0` (IPv4) and `[::]` (IPv6) |

**Conclusion:** SSH was the only listening service found on this machine, exposed on both IPv4 and IPv6. No unexpected or undocumented ports were open. This represents a minimal attack surface — a good security posture, assuming SSH access itself is properly secured (strong passwords or key-based authentication, which is a logical next step to explore).

## Overall Security Assessment

This investigation combined three independent angles — authentication logs, running processes, and open network ports — to build a basic security picture of a single Linux machine, following a simple but effective logic: **raw logs → filtering → timeline → conclusion**.

No signs of compromise were found. The exercise also surfaced two practical lessons that go beyond this specific machine: log messages can reveal more about a failed login than expected (username validity vs. password correctness), and observation tools can bias their own measurements if not used carefully.
