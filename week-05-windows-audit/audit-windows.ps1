# Windows audit script - Week 5 project
Write-Output "=== WINDOWS AUDIT ==="
Get-Date
Write-Output "Machine: $env:COMPUTERNAME"
Write-Output "User: $env:USERNAME"

Write-Output ""
Write-Output "--- Local accounts ---"
Get-LocalUser | Select-Object Name, Enabled

Write-Output ""
Write-Output "--- Members of the Administrators group ---"
# S-1-5-32-544 is the universal ID of the Administrators group, whatever the Windows language
Get-LocalGroupMember -SID S-1-5-32-544 | Select-Object Name

Write-Output ""
Write-Output "--- Services ---"
$running = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
$stopped = (Get-Service | Where-Object { $_.Status -eq "Stopped" }).Count
Write-Output "Running services: $running"
Write-Output "Stopped services: $stopped"

Write-Output ""
Write-Output "--- Startup programs (Run keys) ---"
Write-Output "Current user (HKCU):"
Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" | Select-Object * -ExcludeProperty PS* | Format-List
Write-Output "All users (HKLM):"
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" | Select-Object * -ExcludeProperty PS* | Format-List

Write-Output ""
Write-Output "--- Scheduled tasks outside \Microsoft\Windows\ ---"
# Third-party tasks are where persistence usually hides, so we list only those
Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft\Windows\*" } | Select-Object TaskName, State, TaskPath | Format-List

Write-Output "=== END OF AUDIT ==="
