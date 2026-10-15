# Week 5 – Auditing a Windows machine with PowerShell

A small, read-only PowerShell script that answers three questions about a Windows machine:

1. **Who exists?** Local accounts and members of the Administrators group.
2. **What runs?** Running vs. stopped services.
3. **What starts by itself?** Startup programs (Run keys) and scheduled tasks outside `\Microsoft\Windows\`.

Everything was run in a lab VM (Windows 10 22H2, French language). Personal details are masked in the proofs.

## Files

| File | Content |
|---|---|
| `audit-windows.ps1` | The audit script |
| `audit-report-sample.txt` | Sample output (machine name, user name and SIDs replaced by `XXXX`) |
| `evidence.pdf` | Masked screenshots with short captions |

## How to run

No administrator rights needed. In a normal PowerShell window:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\audit-windows.ps1
```

The first line only affects the current window. The script changes nothing on the system.

## What I learned

- **Protected vs. writable.** `icacls` shows that `whoami.exe` in `System32` is `(RX)` for users and `(F)` only for `TrustedInstaller`. My own `Documents` folder is `(F)` for my account.
- **Same mechanism, different risk.** OneDrive starts through a Run key from my profile folder, where I have full control. SecurityHealth starts from `System32`, which I cannot modify.
- **Two questions for any program that starts by itself:** where does it run from, and who can modify it?
- The Administrators group is read by its SID (`S-1-5-32-544`), so the script works on any Windows language.

## Notes

- The sample report comes from an earlier version of the script, so some headings differ slightly from the current file.
- Tested only on one Windows 10 lab VM.
- Next: Windows hardening and Event Viewer logs.
