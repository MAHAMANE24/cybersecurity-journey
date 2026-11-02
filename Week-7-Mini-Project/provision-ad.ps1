# provision-ad.ps1
# Creates fictional employees in Active Directory (Week 7 mini-project)

$employees = @(
    @{ First = "Ibrahim"; Last = "Diallo";  Dept = "Marketing" },
    @{ First = "David";   Last = "Laporte"; Dept = "Logistics" },
    @{ First = "Andre";   Last = "Dante";   Dept = "IT" }
)

$domainPath = "DC=cyber-lab,DC=local"
$password = $null
$report = @()

Write-Host "Employees in the list:" $employees.Count

foreach ($emp in $employees) {
    $login = ("$($emp.First).$($emp.Last)").ToLower()
    $ouPath = "OU=$($emp.Dept),$domainPath"

    $exists = Get-ADUser -Filter "SamAccountName -eq '$login'"

    if ($exists) {
        Write-Host "Already exists:" $login
    }
    else {
        New-ADUser -Name "$($emp.First) $($emp.Last)" -GivenName $emp.First -Surname $emp.Last -SamAccountName $login -Path $ouPath
        Write-Host "Created:" $login "in" $ouPath
    }

    $user = Get-ADUser -Identity $login
    if (-not $user.Enabled) {
        if ($null -eq $password) {
            $password = Read-Host "Enter the initial password for the accounts" -AsSecureString
        }
        if ($password.Length -eq 0) {
            Write-Warning "Empty password: $login was not enabled."
            $password = $null
        }
        else {
            Set-ADAccountPassword -Identity $login -Reset -NewPassword $password
            Enable-ADAccount -Identity $login
            Write-Host "Enabled:" $login
        }
    }

    $group = "$($emp.Dept)-team"
    $members = Get-ADGroupMember -Identity $group | Select-Object -ExpandProperty SamAccountName
    if ($members -notcontains $login) {
        Add-ADGroupMember -Identity $group -Members $login
        Write-Host "Added to group:" $login "->" $group
    }
    else {
        Write-Host "Already in group:" $login "->" $group
    }

    $final = Get-ADUser -Identity $login
    $report += [PSCustomObject]@{
        Login      = $login
        Department = $emp.Dept
        Enabled    = $final.Enabled
        Group      = $group
    }
}

Write-Host ""
Write-Host "Summary:"
$report | Format-Table -AutoSize