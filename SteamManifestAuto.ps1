# =========================================================
# Steam Manifest Auto Downloader - Pro Version
# Runs in background, monitors Steam downloads, fetches missing manifests
# =========================================================

# CONFIG
$SteamPath = "C:\Program Files (x86)\Steam"
$DepotCachePath = Join-Path $SteamPath "depotcache"
$LuaPathFolder = Join-Path $SteamPath "config\stplug-in"
$CheckIntervalSeconds = 10
$GitHubURLTemplate = "https://raw.githubusercontent.com/qwe213312/k25FCdfEOoEJ42S6/main/{0}_{1}.manifest"
$LogFile = Join-Path $DepotCachePath "manifest_downloader.log"

# FUNCTIONS

function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp - $message"
    Add-Content -Path $LogFile -Value $line
}

function Get-DownloadingGames {
    $path = Join-Path $SteamPath "steamapps\downloading"
    if (!(Test-Path $path)) { return @() }
    return Get-ChildItem $path -Directory
}

function Get-DepotsFromLua {
    param($AppId)
    $luaFile = Join-Path $LuaPathFolder "$AppId.lua"
    if (!(Test-Path $luaFile)) { return @() }

    $depots = @()
    $content = Get-Content $luaFile

    foreach ($line in $content) {
        if ($line -match 'addappid\s*\(\s*(\d+)') {
            $depots += $matches[1]
        }
    }

    return $depots | Select-Object -Unique
}

function Get-AppInfo {
    param($AppId)
    try {
        return Invoke-RestMethod "https://api.steamcmd.net/v1/info/$AppId"
    } catch { return $null }
}

function Get-Manifest {
    param($AppInfo, $AppId, $DepotId)
    try {
        return $AppInfo.data.$AppId.depots.$DepotId.manifests.public.gid
    } catch { return $null }
}

function Download-Manifest {
    param($DepotId, $ManifestId)
    $file = Join-Path $DepotCachePath "${DepotId}_${ManifestId}.manifest"
    if (Test-Path $file) { return }

    $url = $GitHubURLTemplate -f $DepotId, $ManifestId

    try {
        Invoke-WebRequest $url -OutFile $file -ErrorAction Stop
        Log "Downloaded Depot $DepotId ($ManifestId)"
    } catch {
        Log "Failed Depot $DepotId ($ManifestId)"
    }
}

# MAIN LOOP
Log "Steam Manifest Auto Downloader Started in background..."

while ($true) {
    $games = Get-DownloadingGames

    foreach ($g in $games) {
        $AppId = $g.Name
        $depots = Get-DepotsFromLua -AppId $AppId
        if ($depots.Count -eq 0) { continue }

        $appInfo = Get-AppInfo $AppId
        if (!$appInfo) { continue }

        foreach ($depot in $depots) {
            $manifest = Get-Manifest $appInfo $AppId $depot
            if ($manifest) {
                Download-Manifest $depot $manifest
            }
        }
    }

    Start-Sleep -Seconds $CheckIntervalSeconds
}