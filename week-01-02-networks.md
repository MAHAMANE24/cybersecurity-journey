# Week 1-2 — Networking: OSI/TCP-IP Model, DNS, ARP, Wireshark

## Home Network Diagram

(Phone 192.168.1.33 + PC 192.168.1.36) ---> WiFi Router (192.168.1.1 — DHCP + default gateway + DNS) ---> Internet

- **DHCP**: the router automatically assigns an IP address to every device that connects.
- **Default gateway**: the router's IP (192.168.1.1) is the single exit point to the Internet for every device on the local network.
- **DNS**: the router relays devices' DNS queries to the configured DNS server.

## Packet Journey — Example with duolingo.com

When I type `duolingo.com` and hit Enter, here's what happens, layer by layer:

**1. DNS (before anything else)**
My browser doesn't know duolingo.com's IP address. So it queries **DNS** (Domain Name System), which translates the domain name into an IP address. The DNS server responds with the corresponding IP.

**2. Application Layer**
This is the visual interface — what I see and request: Duolingo's homepage.

**3. Presentation Layer**
My request is encrypted via **TLS** (the protocol behind HTTPS), so no one can read it while it's in transit. Once it reaches Duolingo, it's decrypted using their key.

**4. Session Layer**
This lets the site remember me while I browse (e.g. moving between Home, Products, etc.), without having to reconnect on every click. Each site has its own session.

**5. Transport Layer (TCP)**
My data is broken down into small, numbered packets, sent via **TCP** (with acknowledgment of receipt, unlike UDP, which has none) — to make sure nothing gets lost and everything arrives in the right order.

**6. Network Layer**
Packets are addressed via **IP** and routed across the Internet to Duolingo's server.

**7. Data Link Layer**
Locally, my PC talks to my router using the router's **MAC address** (found via the **ARP** protocol), before the data leaves toward the Internet.

**8. Physical Layer**
The router emits **WiFi radio waves** (or transmits via Ethernet cable), and my WiFi card picks them up to establish the physical connection.

## What Wireshark Let Me Verify Firsthand

- On an **unencrypted** site (neverssl.com), I could read in plain text: the GET request, the HTTP response code (200 OK, 301 redirect), and even the page's full HTML.
- On an **HTTPS-encrypted** site (wikipedia.org), the same kind of exchange was completely unreadable — concrete proof that TLS really does protect the content, as seen in theory.
