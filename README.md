# Month 1 Complete: From Network Fundamentals to Hands-On Linux Security

## Overview
In one month, I went from understanding concepts in theory to doing them in practice: capturing and analyzing network traffic, hardening a Linux VM, writing a monitoring script, and solving offensive Linux challenges.

## Before vs. After
| Before | After |
|---|---|
| Never connected via SSH key | Configured key-based SSH and disabled password authentication on my VM |
| Understood scripting in theory | Wrote and ran a Bash monitoring script (`monitoring.sh`) |
| Comfortable with the command line, permissions and navigation | Solved OverTheWire Bandit challenges (levels 0 to 11) |

## What I Learned

**Networking**
- OSI model, ICMP, ARP, HTTP/HTTPS, TLS, SSH, VPN
- Full anatomy of a TCP connection (SYN → SYN-ACK → ACK)
- DNS, NAT, subnetting
- Packet analysis with Wireshark

**Linux**
- Fundamentals, navigation, users, permissions and privileges
- Redirections, pipes, processes and services
- Networking on Linux: IP addresses, open and listening ports
- Logs and investigation, Bash scripting

## Projects
| # | Project | Skills | Report |
|---|---|---|---|
| 1 | Home network diagram + packet journey | Networking | [week-01-02-networks.md](week-01-02-networks.md) |
| 2 | Network traffic deep dive (TCP, DNS, TLS) | Wireshark | [network-traffic-deep-dive.md](network-traffic-deep-dive.md) |
| 3 | NAT / CIDR / IPv6 / traceroute investigation | Networking | [advanced-network-concepts-nat-cidr-traceroute.md](advanced-network-concepts-nat-cidr-traceroute.md) |
| 4 | Linux VM investigation (logs, processes, ports) | Linux, logs | [week-03-04-linux.md](week-03-04-linux.md) |
| 5 | VM hardening: SSH key authentication, password login disabled | Security | [ssh-hardening.md](ssh-hardening.md) |
| 6 | `monitoring.sh`: ports, SSH failures, top CPU processes | Bash scripting | [Bash-monitoring-script.md](Bash-monitoring-script.md) |
| 7 | Wireshark: encrypted SSH vs. cleartext HTTP | Networking + security | [ssh-vs-http-traffic-capture.md](ssh-vs-http-traffic-capture.md) |
| 8 | OverTheWire Bandit (levels 0 to 11) | Offensive Linux | [bandit-levels-0-11.md](bandit-levels-0-11.md) |

*Bandit solutions and passwords are intentionally not published.*

## Key Takeaways
- Reading authentication logs taught me to tell a wrong password from a wrong username, and to see who connected and when.
- Seeing SSH (encrypted) and HTTP (cleartext) side by side in Wireshark made the difference concrete.
- **My method:** learn the theory, ask the right questions, then practice until I understand how it works.

## Next: Month 2
Windows fundamentals, Active Directory and baseline security.
