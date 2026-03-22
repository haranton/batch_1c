param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\.." )).Path,
    [string]$ExtensionName = "batch_1c",
    [string]$ExtensionDir = "src\cfe\batch_1c",
    [ValidateSet("Auto", "Full", "Update")]
    [string]$DumpMode = "Auto",
    [string]$Branch = "main",
    [string]$Remote = "origin"
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$ErrorMessage
    )

    cmd.exe /c $Command
    if ($LASTEXITCODE -ne 0) {
        throw $ErrorMessage
    }
}

Push-Location $RepoRoot
try {
    $configDumpInfoPath = Join-Path $RepoRoot (Join-Path $ExtensionDir "ConfigDumpInfo.xml")
    $useUpdate = $false
    if ($DumpMode -eq "Update") {
        $useUpdate = $true
    } elseif ($DumpMode -eq "Auto" -and (Test-Path $configDumpInfoPath)) {
        $useUpdate = $true
    }

    if ($useUpdate) {
        $dumpCommand = 'call src\1c-batch\scripts\unlock-and-dump-extension.bat "{0}" "{1}" update' -f $ExtensionDir, $ExtensionName
    } else {
        $dumpCommand = 'call src\1c-batch\scripts\unlock-and-dump-extension.bat "{0}" "{1}"' -f $ExtensionDir, $ExtensionName
    }

    Invoke-Step -Command $dumpCommand -ErrorMessage "Выгрузка расширения завершилась с ошибкой"

    Invoke-Step -Command "git add -A" -ErrorMessage "Не удалось добавить изменения в индекс Git"

    cmd.exe /c "git diff --cached --quiet"
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Изменений после выгрузки нет"
        exit 0
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $commitCommand = 'git commit -m "Автовыгрузка расширения {0}"' -f $timestamp
    Invoke-Step -Command $commitCommand -ErrorMessage "Не удалось выполнить git commit"

    $pushCommand = 'git push {0} {1}' -f $Remote, $Branch
    Invoke-Step -Command $pushCommand -ErrorMessage "Не удалось выполнить git push"

    Write-Output "Выгрузка, commit и push выполнены успешно"
}
finally {
    Pop-Location
}
