# ===== INSTALL SCRIPT - Hidden Version =====

$ScriptUrl = "https://raw.githubusercontent.com/sam12345z/K55STORE/refs/heads/main/SteamManifestAuto.ps1"
$InstallPath = "$env:APPDATA\SteamManifestAuto"
$ScriptFile = "$InstallPath\SteamManifestAuto.ps1"
$LogFile = "$InstallPath\install.log"
$TaskName = "SteamManifestAuto"

# إنشاء المجلد إذا لم يكن موجودًا
if (-not (Test-Path $InstallPath)) { New-Item -ItemType Directory -Path $InstallPath | Out-Null }

# تسجيل الحدث في ملف السجل
"[$(Get-Date)] Starting installation..." | Out-File -FilePath $LogFile -Append

# تحميل السكربت الرئيسي من GitHub
Invoke-WebRequest -Uri $ScriptUrl -OutFile $ScriptFile

"[$(Get-Date)] Downloaded SteamManifestAuto.ps1" | Out-File -FilePath $LogFile -Append

# حذف أي مهمة مجدولة قديمة بنفس الاسم
$oldTasks = Get-ScheduledTask | Where-Object {$_.TaskName -eq $TaskName}
foreach ($t in $oldTasks) {
    Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false
    "[$(Get-Date)] Removed old scheduled task: $($t.TaskName)" | Out-File -FilePath $LogFile -Append
}

# إنشاء مهمة مجدولة لتشغيل السكربت مخفي
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptFile`""
$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -RunLevel Highest -Force

"[$(Get-Date)] Installation completed successfully. Task scheduled and running hidden." | Out-File -FilePath $LogFile -Append
