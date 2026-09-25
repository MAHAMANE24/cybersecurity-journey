# Advanced Network Concepts — NAT, CIDR, IPv6 & Traceroute Investigation
 
## 1. Introduction
 
This report covers a set of advanced networking concepts explored after the core Week 1-2 material: NAT, CIDR/subnetting, IPv6 basics, and ICMP/traceroute — applied through a full practical investigation of a real web request, from my local network all the way to the destination server.
 
## 2. NAT (Network Address Translation)
 
My PC's private IP address (192.168.1.10) cannot communicate directly on the public Internet — private IP ranges are only valid within a local network. My router handles the translation: it replaces my private IP with a single shared **public IP address** (verified via whatismyip.com) for all outbound traffic, and every device on my home network shares this same public IP.
 
This is the mechanism that solves IPv4 address scarcity: instead of requiring one public IP per device, an entire household shares one, with the router keeping an internal table (mapping private IP + port ↔ public IP + port) to route responses back to the correct device.
 
## 3. CIDR / Subnetting
 
My home network is `192.168.1.0/24`, meaning the first three blocks (192.168.1) are fixed to identify the network, leaving the last block free for individual devices — a theoretical maximum of 254 usable addresses.
 
Subnetting extends this idea further: increasing the CIDR number (e.g. `/24` → `/25`) splits a network in half, useful for isolating groups of devices (e.g. separating a company's departments) for security and traffic management — though not something applied on a typical home network.
 
## 4. Full Connection Trace: DNS → TCP → TLS (tmtid.com)
 
Using Wireshark, I traced a complete request to `tmtid.com`:
 
```
DNS query           192.168.1.10 → 192.168.1.1         "What's the IP for tmtid.com?" (ID 0x88b3)
DNS response        192.168.1.1 → 192.168.1.10          → 116.203.31.170 (same ID, confirming the match)
 
TCP [SYN]           192.168.1.10 → 116.203.31.170       "I want to connect"
TCP [SYN, ACK]      116.203.31.170 → 192.168.1.10        Acknowledged + reverse synchronization
TCP [ACK]           192.168.1.10 → 116.203.31.170        Connection established
 
TLS Client Hello    192.168.1.10 → 116.203.31.170        SNI = tmtid.com
TLS Server Hello    116.203.31.170 → 192.168.1.10         + Change Cipher Spec + Application Data
TLS Change Cipher   192.168.1.10 → 116.203.31.170         Encryption now active on my side too
```
 
This confirms the same sequence observed in the previous project: name resolution always precedes connection establishment, which in turn precedes encryption negotiation — each layer building on the one before it.
 
## 5. ICMP & Traceroute — Reading the Physical Path
 
### 5.1 ICMP fundamentals (ping)
 
A basic ping to 8.8.8.8 confirmed the request/reply mechanism, matched by a shared ID and sequence number. One key detail: the **TTL (Time To Live)** field decreases by 1 at every router hop — this is the exact mechanism traceroute exploits to map a full path.
 
### 5.2 Traceroute to tmtid.com's server (116.203.31.170)
 
```
Hop 1     sobox-fibre.home [192.168.1.1]           — my own router
Hop 2     Request timed out                         — normal, hop configured to ignore ICMP
Hop 3-4   213.154.92.106 / 196.207.199.192           — local ISP infrastructure (Mali)
Hop 5-7   as6453.net (Tata Communications)           — sz5-seixal → sv8-highbridge
Hop 8-14  as6453.net (Tata Communications)           — pye-paris → pvu-paris (some timeouts)
Hop 15    de-web02.tmtanalysis.com [116.203.31.170]  — destination reached
```
 
**Reading the path geographically:** hostnames encode location clues — `seixal` (Portugal), `highbridge` (a submarine cable landing point in Somerset, **United Kingdom** — confirmed via research, not the United States despite the name's initial ambiguity), and `paris` (France). This traffic therefore travels entirely through Europe (Portugal → UK → France) before reaching its destination — the same Tata Communications route observed in an earlier traceroute to Google, suggesting this is the standard, stable path used by my ISP for international transit.
 
**On the timeouts (hops 2, 8, 9, 11, 14):** these are expected and not errors — many core routers are configured to deprioritize or ignore ICMP traceroute probes for load and security reasons, while still forwarding real traffic normally.
 
## 6. Why This Matters for a Future SOC Role
 
This exercise directly builds a practical skill: reading a network path to establish what "normal" looks like, so that deviations become noticeable. A sudden change in a usually stable route (a new country, an unfamiliar AS, unexpected timing) can be an early indicator of route hijacking or a routing anomaly worth investigating — the same logic applies when tracing the origin of suspicious traffic in a real incident.
 
## 7. Key Takeaways
 
Bringing NAT, CIDR, IPv6, and traceroute together with the earlier DNS/TCP/TLS work gives a complete picture of a single request's journey: from a private IP behind NAT, through a defined local subnet, resolved via DNS, secured via TLS, and physically routed across multiple countries and network operators — all in a fraction of a second. Understanding each layer individually, and how to verify assumptions (like double-checking that "highbridge" wasn't actually in the US) rather than guessing, is exactly the kind of careful, evidence-based reading a SOC analyst relies on daily.
