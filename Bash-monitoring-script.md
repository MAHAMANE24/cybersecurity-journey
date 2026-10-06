# Day 2 — A Bash monitoring script for my Kali VM

**Environment:** Kali Linux VM (VirtualBox), user `kali`, SSH service enabled.
**Goal:** turn the commands I used by hand in Weeks 3–4 into one script that produces a small security report.

## What the script reports

1. **Listening ports** (`ss -tulnp`): what is open on the machine?
2. **Failed SSH logins** (`journalctl` + `grep` + `wc -l`): who tried to get in?
3. **Top 5 CPU processes** (`ps aux` + `sort`): what is using the CPU?

## The script

```bash
#!/bin/bash
# monitoring.sh - Basic security monitoring report for a Linux machine
# Shows: listening ports, failed SSH logins, top 5 CPU processes
# Usage: ./monitoring.sh (runs without sudo)
# Limitation: without sudo, ss cannot show which program owns each port
# (empty "Process" column). Run "sudo ss -tulnp" to see it.
echo "=== LISTENING PORTS ==="
ss -tulnp
echo "=== FAILED SSH LOGINS ==="
echo "Invalid usernames tried:"
journalctl | grep sshd | grep "Invalid user" | wc -l
echo "Failed password tried:"
journalctl | grep sshd | grep "Failed password" | grep -v "invalid user" | wc -l
echo "=== TOP 5 CPU PROCESSES ==="
ps aux | sort -rnk 3 | grep -v "ps aux" | grep -v "sort -rnk 3" | grep -v "head -n 5" | head -n 5
```

Permissions: `chmod 700 monitoring.sh` (`-rwx------`, only the owner can read, write or run it).
Run it with `./monitoring.sh` (the `./` is required because the current directory is not in `PATH`).

## Results

Output of one run (link-local IPv6 address masked, process list trimmed to the main columns):

```
=== LISTENING PORTS ===
Netid State  Recv-Q Send-Q  Local Address:Port    Peer Address:Port
udp   UNCONN 0      0       [fe80::xxxx]%eth0:546 [::]:*
tcp   LISTEN 0      128     0.0.0.0:22            0.0.0.0:*
tcp   LISTEN 0      128     [::]:22               [::]:*
=== FAILED SSH LOGINS ===
Invalid usernames tried:
2
Failed password tried:
1
=== TOP 5 CPU PROCESSES ===
USER   PID    %CPU  COMMAND
root     715   8.9  /usr/lib/xorg/Xorg
root      30   4.8  [ksoftirqd/2]
_apt   39016   3.3  /usr/lib/apt/methods/http
kali    1267   2.3  xfce4 panel plugin (cpugraph)
kali    2489   2.2  /usr/bin/qterminal
```

The only service listening for remote connections is SSH on port 22 (IPv4 and IPv6).

## What I learned

**1. Least privilege is a trade-off.**
My first instinct was to avoid sudo in the script, because I want to build the habit of limiting risk when I configure systems. I still tested `sudo ss -tulnp` to see the difference: with sudo, the Process column shows `sshd` (PID 702) and `NetworkManager`; without it, the column is empty, because a normal user cannot see processes owned by root. I kept the script without sudo (no password needed, minimal privileges) and documented the limitation in the script header.

**2. A monitoring command can show up in its own output.**
My first top-CPU list was led by my own commands (`ps aux`, `sort`...), with an inflated %CPU (200%). `ps` computes %CPU as CPU time divided by the time since the process started, which is very high for a brand-new process. I added `grep -v` filters to remove them. In later runs they did not appear, but I kept the filter as a safeguard.

**3. One failed login can leave several log lines.**
I first assumed that "Invalid user" and "Failed password" counted the same attempts, and I predicted 0 results when searching for `Invalid user` with a capital I. Reading the raw logs showed otherwise: `qwert` produced both lines, `kai` only produced "Invalid user" followed by a disconnect (no password was ever sent), and `kali` produced a "Failed password" for a valid user. So I count two separate things and label them precisely: invalid usernames tried (2) and failed passwords for valid users (1). Counting lines is not the same as counting attempts.

## Limitations and next steps

- Without sudo, the **Process** column of `ss` stays empty. This is a deliberate choice, documented in the script.
- The counts cover everything in the journal, with no time filter, so they accumulate over time.
- The report is only printed to the screen. A next step is to save it to a file and compare runs.
