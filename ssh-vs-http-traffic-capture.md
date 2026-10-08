# SSH vs HTTP: What Can a Network Observer See?

I captured the same kind of traffic twice in my home lab, once over SSH (encrypted) and once over HTTP (plaintext), and compared what Wireshark can see.

**Full report with screenshots:**

## Key findings

- **HTTP exposes everything.** A fake password, the requested path, my browser, my operating system and the server software were all readable in the capture.
- **SSH protects the content.** After the `New Keys` messages, my commands and their output were unreadable, even in Wireshark's Follow TCP Stream view.
- **Encryption does not hide the conversation itself.** An observer still sees who talks to whom, on which port, with which software versions, and how much data moves.

## Lab environment

| Role | Machine | IP address |
|---|---|---|
| Client | Windows host (physical machine) | 192.168.1.8 |
| Server and capture point | Kali Linux virtual machine | 192.168.1.39 |

Tools: `tcpdump`, Wireshark, PuTTY 0.82, OpenSSH server, `python3 -m http.server`.

Everything was done on my own machines and network. The "password" is a fake value created only for this experiment.

## Method

All captures were recorded inside the Kali VM with `tcpdump`, then analyzed in Wireshark.

**SSH capture**

```bash
sudo tcpdump -i eth0 -w ssh2.pcap port 22
```

I opened an SSH session from the Windows host with PuTTY (key-based authentication), typed `whoami`, `ls` and `pwd`, then closed it. Result: 151 packets captured.

**HTTP capture**

```bash
mkdir ~/test_http && cd ~/test_http
echo "mot_de_passe=azerty123" > secret.txt
python3 -m http.server 8000
```

```bash
sudo tcpdump -i eth0 -w http.pcap port 8000
```

I then requested `http://192.168.1.39:8000/secret.txt` from the Windows host browser.

## What an observer can see

| | SSH (port 22) | HTTP (port 8000) |
|---|---|---|
| Who talks to whom (IP addresses) | Visible | Visible |
| Protocol and port | Visible | Visible |
| Client and server software | Visible (banners) | Visible (headers) |
| Packet sizes and timing | Visible | Visible |
| What was requested | **Hidden** | **Visible** |
| Content exchanged | **Hidden** | **Visible** |

## Challenges and lessons

- **Zero packets captured.** My first HTTP capture was empty because I had opened the browser inside the VM, so the traffic used the loopback interface instead of `eth0`. The server's access log showed the VM's own address as the client, which revealed the mistake.
- **Capture location.** Wireshark on the Windows host did not show the VM's ping traffic, even though all 68 pings got a reply. Moving the capture inside the VM with `tcpdump` removed the ambiguity.

## Takeaways

1. Never send credentials over a plaintext protocol such as HTTP.
2. SSH creates a temporary session key for each connection, so a recorded session stays unreadable later.
3. Before interpreting a capture, check what it can actually see.

## Limits

A small home-lab test on a local network, with one session of each protocol. It shows the principle clearly but does not cover other observer positions or other protocols.
