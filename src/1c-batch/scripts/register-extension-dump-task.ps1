param(
    [string]$TaskName = "OneC_ExtensionDump",
    [string]$At = "03:00",
    [Parameter(Mandatory = $true)][string]$ExtensionName,
    [string]$ExtensionDir = "",
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
}

if ([string]::IsNullOrWhiteSpace($ExtensionDir)) {
    $ExtensionDir = "src\\cfe\\$ExtensionName"
}

$scriptPath = Join-Path $scriptDir "dump-extension-and-push.ps1"
$args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -RepoRoot `"$RepoRoot`" -ExtensionName `"$ExtensionName`" -ExtensionDir `"$ExtensionDir`""

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $args
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$userId = "{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Output "Задача $TaskName зарегистрирована. Ежедневный запуск в $At"
Write-Output "Расширение: $ExtensionName"
Write-Output "Каталог выгрузки: $ExtensionDir"


