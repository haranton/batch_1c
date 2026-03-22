param(
    [Parameter(Mandatory = $true)]
    [string]$RacPath,
    [Parameter(Mandatory = $true)]
    [string]$Agent,
    [Parameter(Mandatory = $true)]
    [string]$InfobaseName
)

$ErrorActionPreference = "SilentlyContinue"

if (-not (Test-Path -LiteralPath $RacPath)) {
    exit 1
}

function Invoke-Rac {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & $RacPath $Agent @Args
}

$clustersRaw = Invoke-Rac cluster list
if ($LASTEXITCODE -ne 0) {
    exit 1
}

$clusterIds = @()
foreach ($line in $clustersRaw) {
    if ($line -match "cluster\s*:\s*([0-9a-fA-F-]{36})") {
        $clusterIds += $Matches[1]
    }
}

if ($clusterIds.Count -eq 0) {
    exit 1
}

$terminated = 0

foreach ($clusterId in $clusterIds) {
    $infobasesRaw = Invoke-Rac infobase --cluster=$clusterId summary list
    if ($LASTEXITCODE -ne 0) {
        continue
    }

    $matchedInfobaseId = $null
    $currentInfobaseId = $null
    foreach ($line in $infobasesRaw) {
        if ($line -match "infobase\s*:\s*([0-9a-fA-F-]{36})") {
            $currentInfobaseId = $Matches[1]
            continue
        }

        if ($line -match "name\s*:\s*(.+)$") {
            $currentName = $Matches[1].Trim()
            if ($currentInfobaseId -and $currentName -eq $InfobaseName) {
                $matchedInfobaseId = $currentInfobaseId
                break
            }
        }
    }

    if (-not $matchedInfobaseId) {
        continue
    }

    $sessionsRaw = Invoke-Rac session --cluster=$clusterId list --infobase=$matchedInfobaseId
    if ($LASTEXITCODE -ne 0) {
        continue
    }

    $sessionId = $null
    $appInfo = ""

    foreach ($line in $sessionsRaw) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($sessionId -and $appInfo -match "(designer|configurator)") {
                Invoke-Rac session --cluster=$clusterId terminate --session=$sessionId | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $terminated++
                }
            }

            $sessionId = $null
            $appInfo = ""
            continue
        }

        if ($line -match "session\s*:\s*([0-9a-fA-F-]+)") {
            $sessionId = $Matches[1]
        }

        if ($line -match "([^:]+)\s*:\s*(.*)$") {
            $key = $Matches[1].Trim().ToLowerInvariant()
            $value = $Matches[2].Trim()
            if ($key -in @("app-id", "app", "application", "client-application-name")) {
                $appInfo = ($appInfo + " " + $value).Trim()
            }
        }
    }

    if ($sessionId -and $appInfo -match "(designer|configurator)") {
        Invoke-Rac session --cluster=$clusterId terminate --session=$sessionId | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $terminated++
        }
    }
}

if ($terminated -gt 0) {
    exit 0
}

exit 1
