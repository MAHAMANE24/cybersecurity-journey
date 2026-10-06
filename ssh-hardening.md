# Hardening SSH on a Kali Linux VM

**Hands-on practice week, Day 1** | Key-based authentication, password login disabled

## Goal
Allow SSH access to my Kali Linux VM only with a key pair, and prove that password login is closed.

## What I did
1. Generated an RSA key pair with PuTTYgen (passphrase-protected private key)
2. Added the public key to `~/.ssh/authorized_keys`
3. Set permissions `700` on `~/.ssh` and `600` on `authorized_keys`
4. Tested key login while keeping an existing session open as a safety net
5. Set `PasswordAuthentication no` in `/etc/ssh/sshd_config` and restarted SSH

## Verification (3 independent checks)
- `sudo sshd -T` shows `pubkeyauthentication yes` and `passwordauthentication no`
- Login without the private key is refused: `No supported authentication methods available (server sent: publickey)`
- Logs: last `Accepted password` at 23:53:00, only `Accepted publickey` afterwards

## Lesson learned
My first attempt left a `#` at the start of the line. Password login still worked: a commented line is ignored, so SSH falls back to its default (`yes`). Removing the `#` made the setting effective.

## Limitations
- Private-network lab: the logs I reviewed contain no failed password attempts, so this demonstrates a configuration and its verification, not a response to an attack.
- The private key and its passphrase are now the only way in over SSH.
- I did not run `sudo sshd -t` (syntax check) before restarting the service. Next time I will.

## Full report
[ssh-hardening-lab-report.pdf](https://github.com/user-attachments/files/33083092/ssh-hardening-lab-report.pdf) (6 pages, 6 screenshots)
