# OverTheWire Bandit: Levels 0 to 11

## Context
[OverTheWire Bandit](https://overthewire.org/wargames/bandit/) is a wargame that teaches the Linux command line through SSH. Each level hides the password for the next account somewhere on a real remote server. This project is part of my 6-month cybersecurity roadmap, right after Month 1 (networking and Linux).

I reached the `bandit11` account. I did not publish any password or full solution, so that others can enjoy solving the levels themselves.

**Proof of work:** see [bandit-levels-0-11-proof.pdf](https://github.com/user-attachments/files/33269016/bandit-levels-0-11-proof.pdf)
 (one login screenshot per account, plus the commands that illustrate the method). 

## Levels 0 to 4: navigating the server and finding hidden files

**Goal.** Each level hides the password for the next account somewhere on the server. In these first levels, the challenge is mostly about moving around the file system and reading the right file.

**Approach.** I connected over SSH (port 2220), explored the directories and read the files that held the password. In some levels the password was stored in a hidden file. A plain `ls` does not show those, so I used `ls -la`:
- `-a` lists all entries, including hidden ones (names starting with a dot);
- `-l` shows the long format, with permissions, owner and size.

**What I learned.**
- The Linux basics from my previous weeks (navigation, listing, reading files) work exactly the same on a real remote server.
- A file can exist without appearing in a default listing, so "nothing there" does not always mean "empty".

**What I enjoyed most.** Logging in to a remote server for the first time. After setting up SSH on my own VM, being the client of a real server gave me a first concrete glimpse of how SSH is used in practice.

## Level 5 to 6: finding a file among many by its properties

**Goal.** The password was in one file, somewhere in a directory containing many subdirectories. The level gave its properties: human-readable, 1033 bytes in size, and not executable.

**Approach.** I did not have a clear plan at first, so I went through the directories one by one. In each one I listed the files in long format (`ls -la`) and compared the sizes and permissions with the clues, until I found the file that matched all of them.

**What I learned.**
- Listing with `ls -la` is enough to check size and permissions, and the `x` in the permissions tells whether a file is executable.
- This manual method worked, but it was slow. When clues describe a file's properties, a search command like `find` (used in the next level) is much faster than checking each directory by hand.

## Level 6 to 7: finding a file by its properties with `find`

**Goal.** The password was in a file somewhere on the whole server. The level did not give its location, only its properties: the owner, the owning group and its size in bytes.

**Command (structure).**

    find / -user <owner> -group <group> -size <N>c 2>/dev/null

**How it works.**
- `/`: start the search from the root, since the file could be anywhere.
- `-user`, `-group`, `-size`: one option per clue. Combined, they narrow thousands of files down to a single result.
- `c` after the size: without a unit letter, `find` counts in blocks, not bytes. The `c` suffix means bytes.
- `2>/dev/null`: searching from `/` produces hundreds of "Permission denied" errors, because my account cannot enter many directories. Errors travel through a separate channel (stderr, number 2). Redirecting it to `/dev/null`, a "black hole", keeps only the useful result on screen.

**What I learned.**
- When a level gives properties instead of a location, `find` is the right tool: it filters among countless files instead of browsing them one by one.
- I thought about how to search before typing, rather than trying commands at random.

## Level 7 to 8: finding a word in a large file

**Goal.** The password was stored in a text file, next to a specific word given in the level.

**Command (structure).**

    cat <file> | grep <word>

**How it works.** `cat` prints the file and `grep` keeps only the lines containing the word. The file is long, so filtering is much faster than reading it. (`grep <word> <file>` gives the same result without `cat`, which I noted for next time.)

**What I learned.** `grep` turns "reading a huge file" into "asking it a question".

## Level 8 to 9: finding the only unique line in a file

**Goal.** The password was the only line of a text file that appeared exactly once. All other lines were repeated.

**Command (structure).**

    sort <file> | uniq -u

**How it works.**
- `sort` orders the lines alphabetically, so identical lines end up next to each other.
- `uniq -u` keeps only the lines that appear once. It only detects duplicates that are adjacent, which is why `sort` must come first.
- The pipe `|` sends the sorted output of the first command into the second.

**What I learned.** Chaining small commands with a pipe lets me solve a problem that would be painful by hand. I had already used pipes in my Linux projects, and here I applied the same idea to a new problem.

## Level 9 to 10: extracting readable text from a binary file

**Goal.** The password was in a file mostly made of unreadable data. It was one of the few human-readable strings, preceded by several `=` characters.

**Approach.** I first tried `cat`, which printed unreadable characters and showed that the file was not plain text. I then used:

    strings <file> | grep "<pattern>"

**How it works.**
- `strings` extracts only the sequences of printable characters from a binary file.
- `grep` then keeps the line that matches the clue given in the level.

**What I learned.** A file that looks unreadable can still contain readable text. `strings` is a quick first look at a binary file.

## Level 10 to 11: Base64 decoding

**Goal.** The password was in a file containing Base64-encoded data.

**Approach.** `cat` showed a short block of text that looked meaningless. I recalled that the level said "Base64", and my first attempt was `base64 <file>`. That did not help: the command encodes by default, so it encoded the data a second time. I then used the decode option:

    base64 -d <file>

**What I learned.**
- Reading the clue carefully matters: the data was already encoded, so I needed to decode, not encode.
- Base64 is an encoding, not encryption. There is no key: anyone can decode it with one command. It makes data transportable, not secret.

## What's next
I stopped at level 11 on purpose: the next levels rely on encoding and encryption concepts that are not yet in my roadmap. Once I have studied them properly, I will continue from level 11.
