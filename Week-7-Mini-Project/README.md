# Week 7 Mini-Project: Active Directory User Provisioning Script (PowerShell)

Part of my 6-month cybersecurity roadmap. After building and organizing an Active Directory lab (`cyber-lab.local`) by hand, I automated the user provisioning in one PowerShell script.

## What the script does

For each employee in a list:

1. Builds the login (`firstname.lastname`, lowercase) and the OU path (`OU=<Department>,DC=cyber-lab,DC=local`).
2. Creates the account **only if it does not exist**.
3. If the account is disabled, sets the password and **enables** it.
4. Adds the employee to the team group of the department (`Marketing-team`, `Logistics-team`, `IT-team`), unless already a member.
5. Prints a **summary table** at the end.

## Requirements

- Run on the domain controller, in PowerShell as administrator.
- The OUs (`Marketing`, `Logistics`, `IT`) and the groups (`<Department>-team`) already exist.

## How I built it

I built it one idea at a time, checking the output after each step.

### 1. A list of records

```powershell
$employees = @(
    @{ First = "Ibrahim"; Last = "Diallo";  Dept = "Marketing" },
    @{ First = "David";   Last = "Laporte"; Dept = "Logistics" },
    @{ First = "Andre";   Last = "Dante";   Dept = "IT" }
)
```

### 2. A loop that builds the login and the OU path

```powershell
foreach ($emp in $employees) {
    $login = ("$($emp.First).$($emp.Last)").ToLower()
    $ouPath = "OU=$($emp.Dept),$domainPath"
}
```

The same login format for everyone makes the script predictable.

### 3. Create the account only if it does not exist

```powershell
$exists = Get-ADUser -Filter "SamAccountName -eq '$login'"
if ($exists) { ... } else { New-ADUser ... }
```

A second run prints `Already exists` for each account, with no error: the script is safe to re-run.

### 4. Enable with a password that is never stored in the file

```powershell
$password = Read-Host "Enter the initial password for the accounts" -AsSecureString
Set-ADAccountPassword -Identity $login -Reset -NewPassword $password
Enable-ADAccount -Identity $login
```

New accounts are created **disabled**, and enabling one without a valid password fails. The password is asked at run time and kept as a `SecureString`, so anyone who opens the script cannot read it.

### 5. Add the employee to the team group

```powershell
$group = "$($emp.Dept)-team"
Add-ADGroupMember -Identity $group -Members $login
```

The script checks the current members first, so a re-run does not fail.

### 6. A summary table

Each loop turn adds a row (`Login`, `Department`, `Enabled`, `Group`) to a list, printed at the end with `Format-Table`.

## Testing: two flaws found and fixed

While reading the output, I noticed two problems:

1. **The password was asked even when nothing needed it** (all accounts were already enabled).
2. **An empty password was accepted silently.**

Fix: the script now asks for the password only when a disabled account needs one, and refuses an empty one:

```powershell
if ($password.Length -eq 0) {
    Write-Warning "Empty password: $login was not enabled."
}
```

To test it, I disabled one account on purpose (`Disable-ADAccount`), pressed Enter on the prompt (warning shown, account stays disabled), then ran the script again with a valid password (account enabled).

## Example output

```text
Employees in the list: 3
Already exists: ibrahim.diallo
Already in group: ibrahim.diallo -> Marketing-team
Already exists: david.laporte
Already in group: david.laporte -> Logistics-team
Already exists: andre.dante
Already in group: andre.dante -> IT-team

Summary:

Login          Department Enabled Group
-----          ---------- ------- -----
ibrahim.diallo Marketing     True Marketing-team
david.laporte  Logistics     True Logistics-team
andre.dante    IT            True IT-team
```

## Limits

- The employee list is written inside the script. Next step: read it from a CSV file.
- It assumes the OUs and groups already exist.
- Everyone gets the same initial password. Acceptable in a lab only.
- No log file: the screen output is the only record.

## What I learned

- A script that works once is not finished: run it twice, then try to break it.
- Check if something exists before creating it.
- Never store a password in the file: ask at run time.
- Refuse invalid input and say why.
- Build in small steps and verify each one.
