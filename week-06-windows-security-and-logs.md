# Week 6: Windows Security Basics and Logs

Part of my 6-month cybersecurity roadmap (Month 2). Learning in public, mistakes included.

**Lab:** Windows 10 VM in VirtualBox (isolated personal lab).
**Privacy:** username, hostname and the last octet of the IP address are masked.

## What I covered

| Day | Topic | Main takeaway |
|---|---|---|
| 1 | Listening ports and the firewall | A port that listens is not necessarily exposed |
| 2 | Reading firewall rules | A rule set to `Allow` but disabled does nothing |
| 3 | Event logs: logons (4624, 4625) | The event ID says what happened, the logon type says how |
| 4 | Event logs: accounts (4720, 4726) | Logs keep the history, not the current state |
| 5 | Mini-project | One PowerShell script that runs all the checks |

## Files

- [Carousel PDF] [week-06-windows-security-and-logs.pdf](https://github.com/user-attachments/files/33787388/week-06-windows-security-and-logs.pdf)

): the visual recap
- [Full report] [windows-security-baseline-week6.md](https://github.com/user-attachments/files/33787407/windows-security-baseline-week6.md)

): commands, findings and the mistakes I made

## Limits

- One lab VM with a short log history.
- The firewall was read from its configuration, not tested from the outside.

## Next steps

- Add a block for deleted accounts (event 4726) to the script.
- Identify the programs behind ports 5040 and 7680.
