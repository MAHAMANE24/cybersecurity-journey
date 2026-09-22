# Network Traffic Deep Dive — Week 2 Practical Project
 
## 1. Introduction
 
For this project, I used Wireshark to capture and analyze real traffic on my own home network, in order to understand — with concrete, hands-on examples — how DNS resolution, TCP connections, and TLS encryption actually work together when accessing a website.
 
## 2. Network Mapping
 
I used `arp -a` to check which devices my PC had directly communicated with on the local network. The only entry found was my WiFi router (192.168.1.1), confirmed by its MAC address matching what I had already identified previously.
 
This is expected behavior, not a limitation of the tool: `arp -a` only lists devices your PC has *directly* exchanged data with. Since all outbound traffic (to any external site) only requires knowing the router's MAC address — the router itself handles routing further — other devices on the home network (if any) won't appear unless the PC talks to them directly.
 
I attempted to access the router's admin panel (192.168.1.1) to get a complete list of all connected devices, but I couldn't log in — the router had previously been reset, and the default credentials no longer work. I decided not to reset it again to avoid the risk of losing the ISP connection configuration. This step remains incomplete, but the core networking concepts were still fully verified through the router's confirmed presence in the ARP table.
 
## 3. TCP Three-Way Handshake & Connection Teardown
 
Using a live capture, I identified a complete TCP connection lifecycle — from opening to closing — between my PC (192.168.1.6) and an external server (216.137.44.124) on port 443 (HTTPS):
 
**Opening (three-way handshake):**
```
[SYN]        192.168.1.6 → 216.137.44.124   Seq=0
[SYN, ACK]   216.137.44.124 → 192.168.1.6   Seq=0 Ack=1
[ACK]        192.168.1.6 → 216.137.44.124   Seq=1 Ack=1
```
1. My PC sends a `SYN`: "I want to open a connection."
2. The server replies with `SYN, ACK` in a single packet: "I acknowledge your request, and here is my own synchronization request in return."
3. My PC replies with a final `ACK`: "Acknowledged — the connection is now established."
 
**Closing (four-way teardown, partially combined):**
```
[FIN, ACK]   192.168.1.6 → 216.137.44.124   Seq=2171 Ack=1564
[FIN, ACK]   216.137.44.124 → 192.168.1.6   Seq=1564 Ack=2172
[ACK]        192.168.1.6 → 216.137.44.124   Seq=2172 Ack=1565
```
My PC signals it has finished sending data (`FIN`) while also acknowledging the last data received (`ACK`). The server does the same in return, combining its own `FIN` and `ACK` into one packet. A final `ACK` from my PC confirms the connection is fully closed. The whole connection lasted about 83 seconds between opening and closing.
 
## 4. DNS Resolution Analysis
 
I captured DNS traffic while visiting Snapchat.com and Roblox.com. Each DNS exchange is a request/response pair, identifiable by a shared **transaction ID** (a hexadecimal code) — this is the key detail that lets you match a response to its original request, even when many unrelated DNS packets are mixed together in the capture.
 
Example (Snapchat.com):
```
Standard query          0x45fb   A   snapchat.com
Standard query response 0x45fb   A   snapchat.com   A 34.149.46.130
```
Both the query and its response share the same ID (`0x45fb`) and the same record type (`A`, meaning an IPv4 address) — confirming they belong to the same exchange. The response provides the actual IP address (34.149.46.130) that will be used for the following TCP connection.
 
Using **Follow → UDP Stream** on this exchange, I could see the domain name (e.g. "snapchat.com") appear in **plain, unencrypted text** within the raw packet data — confirming that standard DNS queries are not encrypted by default, even when the website itself later uses HTTPS.
 
## 5. Full Connection Trace, End-to-End
 
Using sysdream.com as an example, I traced a complete request from the initial DNS lookup through to the TLS handshake, confirming the exact order in which these steps occur in practice:
 
```
DNS query           192.168.1.34 → 192.168.1.1        "What's the IP for sysdream.com?"
DNS response        192.168.1.1 → 192.168.1.34         → 37.59.251.196
 
TCP [SYN]           192.168.1.34 → 37.59.251.196       "I want to connect"
TCP [SYN, ACK]      37.59.251.196 → 192.168.1.34        "Acknowledged, and here's mine"
TCP [ACK]           (connection established)
 
TLS Client Hello    192.168.1.34 → 37.59.251.196       SNI = sysdream.com
TLS Server Hello    37.59.251.196 → 192.168.1.34        + Change Cipher Spec + Application Data
```
 
One notable detail: even inside an encrypted TLS handshake, the **SNI (Server Name Indication)** field — the domain name being requested — is still sent in plain text at the very start of the negotiation, before encryption is active. This means that although the *content* of an HTTPS connection is protected, the *domain name* being accessed is still visible to anyone monitoring the network — the same limitation observed earlier with DNS queries.
 
## 6. Key Takeaways
 
The clearest lesson from this week was seeing, firsthand, the real difference between unencrypted (HTTP) and encrypted (HTTPS) traffic. Both actually run over **TCP**, not UDP — UDP is what DNS uses for its lightweight query/response exchanges. The real distinction is that HTTPS adds a **TLS encryption layer** on top of the TCP connection, while plain HTTP does not.
 
On an unencrypted HTTP site, I could read the entire exchange in plain text with Wireshark — the request, the response headers, and even the full HTML content of the page. On an HTTPS site, the equivalent traffic was completely unreadable, confirming that TLS genuinely protects the content of a connection — something I had only understood in theory before this project, and now verified with my own hands.
