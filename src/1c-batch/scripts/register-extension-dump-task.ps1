param(
    [string]$TaskName = "OneC_ExtensionDump",
    [string]$At = "03:00",
    [string]$ExtensionName = "batch_1c",
    [string]$ExtensionDir = "src\cfe\batch_1c",
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\.." )).Path
)

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "dump-extension-and-push.ps1"
$args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -RepoRoot `"$RepoRoot`" -ExtensionName `"$ExtensionName`" -ExtensionDir `"$ExtensionDir`""

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $args
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$userId = "{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType InteractiveToken -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Output "Задача $TaskName зарегистрирована. Ежедневный запуск в $At"
