# ===== INSTALL SCRIPT =====

$ScriptUrl = "https://raw.githubusercontent.com/USERNAME/REPO/main/SteamManifestAuto.ps1"
$InstallPath = "$env:APPDATA\SteamManifestAuto"
$ScriptFile = "$InstallPath\SteamManifestAuto.ps1"

Write-Host "Installing Steam Manifest Auto..."

# Create folder
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null

# Download main script
Invoke-WebRequest $ScriptUrl -OutFile $ScriptFile

# Create Scheduled Task (hidden)
$action = New-ScheduledTaskAction `
 -Execute "powershell.exe" `
 -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptFile`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
 -TaskName "SteamManifestAuto" `
 -Action $action `
 -Trigger $trigger `
 -RunLevel Highest `
 -Force

Write-Host "Installed successfully and running in background."