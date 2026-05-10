# ============================================================
#  phase3_cleanup.ps1
#  Deep system cleanup:
#    1. Windows Disk Cleanup (cleanmgr) via registry sageset
#    2. Manually wipe temp/junk/cache folders
#    3. Clear Windows Update cache (SoftwareDistribution)
#    4. Clear browser caches (Chrome, Edge, Firefox)
#    5. Remove Windows.old if present
#    6. DISM component store cleanup
#    7. DNS cache flush
# ============================================================

$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string]$Message)
    Write-Host "`n[PHASE 3] $Message" -ForegroundColor Cyan
}

function Remove-FolderContents {
    param([string]$FolderPath, [string]$Description)
    Write-Host "  -> Clearing: $Description" -ForegroundColor Yellow
    if (Test-Path $FolderPath) {
        try {
            Get-ChildItem -Path $FolderPath -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "     [OK] Cleared: $FolderPath" -ForegroundColor Green
        }
        catch {
            Write-Host "     [PARTIAL] $FolderPath : $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "     [SKIP] Path not found: $FolderPath" -ForegroundColor DarkGray
    }
}

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  WOS-Cleanup  |  Phase 3 — Deep System Cleanup            " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

# ── 1. Configure and run Windows Disk Cleanup (cleanmgr) ────
Write-Step "Configuring Windows Disk Cleanup (cleanmgr sageset) ..."

$cleanmgrCategories = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "Content Indexer Cleaner",
    "D3D Shader Cache",
    "Delivery Optimization Files",
    "Device Driver Packages",
    "Downloaded Program Files",
    "GameNewsFiles",
    "GameStatisticsFiles",
    "GameUpdateFiles",
    "Internet Cache Files",
    "Memory Dump Files",
    "Offline Pages Files",
    "Old ChkDsk Files",
    "Previous Installations",
    "Recycle Bin",
    "RetailDemo Offline Content",
    "Service Pack Cleanup",
    "Setup Log Files",
    "System error memory dump files",
    "System error minidump files",
    "Temporary Files",
    "Temporary Setup Files",
    "Temporary Sync Files",
    "Thumbnail Cache",
    "Update Cleanup",
    "Upgrade Discarded Files",
    "User file versions",
    "Windows Defender",
    "Windows Error Reporting Archive Files",
    "Windows Error Reporting Queue Files",
    "Windows Error Reporting System Archive Files",
    "Windows Error Reporting System Queue Files",
    "Windows ESD installation files",
    "Windows Upgrade Log Files"
)

$volCachePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
foreach ($cat in $cleanmgrCategories) {
    $regPath = "$volCachePath\$cat"
    try {
        if (Test-Path $regPath) {
            Set-ItemProperty -Path $regPath -Name "StateFlags0001" -Value 2 -Type DWord -Force -ErrorAction Stop
        }
    }
    catch { }
}

Write-Host "  -> Launching cleanmgr /sagerun:1 (may take a few minutes) ..." -ForegroundColor Yellow
try {
    $proc = Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -PassThru -ErrorAction Stop
    if ($proc.ExitCode -eq 0) {
        Write-Host "     [OK] Disk Cleanup completed." -ForegroundColor Green
    } else {
        Write-Host "     [WARN] cleanmgr exited with code $($proc.ExitCode)." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "     [SKIP] cleanmgr: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 2. Manual temp/junk folder wipe ─────────────────────────
Write-Step "Wiping temporary and junk folders ..."

Remove-FolderContents "$env:TEMP"                                         "Current User Temp"
Remove-FolderContents "C:\Windows\Temp"                                   "Windows System Temp"
Remove-FolderContents "C:\Windows\Prefetch"                               "Prefetch Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Temp"                            "LocalAppData Temp"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"     "IE/Edge Legacy Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"      "Windows WebCache"
Remove-FolderContents "$env:LOCALAPPDATA\CrashDumps"                      "Crash Dumps"
Remove-FolderContents "C:\Windows\Logs\CBS"                               "CBS Logs"
Remove-FolderContents "C:\Windows\Logs\DISM"                              "DISM Logs"
Remove-FolderContents "C:\Windows\Logs\MeasuredBoot"                      "MeasuredBoot Logs"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"      "Explorer Thumbnail Cache"
Remove-FolderContents "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations" "Recent Files Jump Lists"
Remove-FolderContents "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"    "Recent Files Custom Jump Lists"

# Event logs — skip Security and System logs (compliance + OS stability)
Write-Host "  -> Clearing Windows Event Logs (excluding Security and System) ..." -ForegroundColor Yellow
try {
    $logs = & wevtutil el 2>$null
    $skipLogs = @('Security', 'System')
    $cleared = 0
    foreach ($log in $logs) {
        if ($skipLogs -contains $log) { continue }
        try {
            & wevtutil cl "$log" 2>$null
            $cleared++
        } catch { }
    }
    Write-Host "     [OK] $cleared event logs cleared (Security and System preserved)." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Event logs: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Recycle Bin (all drives)
Write-Host "  -> Emptying Recycle Bin ..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "     [OK] Recycle Bin emptied." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Recycle Bin: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 3. Windows Update cache (SoftwareDistribution) ──────────
Write-Step "Clearing Windows Update cache ..."

$wuServices = @("wuauserv", "bits", "cryptsvc", "msiserver")

Write-Host "  -> Stopping Windows Update services ..." -ForegroundColor Yellow
foreach ($svc in $wuServices) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "     [OK] Stopped: $svc" -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $svc : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

Remove-FolderContents "C:\Windows\SoftwareDistribution\Download"     "Windows Update Download Cache"
Remove-FolderContents "C:\Windows\SoftwareDistribution\DataStore"    "Windows Update DataStore"

# catroot2: NEVER wipe all contents — it holds code-signing catalog DBs and full deletion
# can cause 0x80080005 update failures requiring manual DLL re-registration to recover.
# Safe approach: only remove the lock/temp files that accumulate and block updates.
Write-Host "  -> Clearing catroot2 lock/temp files only ..." -ForegroundColor Yellow
try {
    $catroot2 = "C:\Windows\System32\catroot2"
    if (Test-Path $catroot2) {
        Get-ChildItem -Path $catroot2 -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @('.tmp', '.log') -or $_.Name -like 'tmp*' } |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "     [OK] catroot2 temp/lock files cleared." -ForegroundColor Green
    }
}
catch {
    Write-Host "     [SKIP] catroot2 cleanup: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "  -> Restarting Windows Update services ..." -ForegroundColor Yellow
foreach ($svc in $wuServices) {
    try {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "     [OK] Started: $svc" -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $svc : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ── 4. Browser cache cleanup ─────────────────────────────────
Write-Step "Clearing browser caches ..."

# Microsoft Edge
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "Edge Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache" "Edge Code Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\GPUCache" "Edge GPU Cache"

# Google Chrome
Remove-FolderContents "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Chrome Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache" "Chrome Code Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache" "Chrome GPU Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Google\Chrome\User Data\ShaderCache" "Chrome Shader Cache"

# Mozilla Firefox
$firefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $firefoxProfiles) {
    Get-ChildItem -Path $firefoxProfiles -Directory | ForEach-Object {
        Remove-FolderContents "$($_.FullName)\cache2" "Firefox Cache ($($_.Name))"
        Remove-FolderContents "$($_.FullName)\thumbnails" "Firefox Thumbnails ($($_.Name))"
        Remove-FolderContents "$($_.FullName)\startupCache" "Firefox Startup Cache ($($_.Name))"
    }
}

# Brave
Remove-FolderContents "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache" "Brave Cache"
Remove-FolderContents "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache" "Brave Code Cache"

# ── 5. Remove Windows.old ────────────────────────────────────
Write-Step "Removing Windows.old (previous Windows installation) ..."

if (Test-Path "C:\Windows.old") {
    Write-Host "  -> Found C:\Windows.old — removing via DISM /startcomponentcleanup /resetbase ..." -ForegroundColor Yellow
    try {
        # /resetbase removes Windows.old and resets the component store baseline on Win10/11.
        # /spsuperseded is the old Win7/Server 2008 flag and has no effect here.
        $proc = Start-Process -FilePath "dism.exe" `
            -ArgumentList "/online /cleanup-image /startcomponentcleanup /resetbase" `
            -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Write-Host "     [OK] Windows.old and superseded components removed via DISM." -ForegroundColor Green
        } else {
            Write-Host "     [INFO] DISM /resetbase returned $($proc.ExitCode), trying direct removal ..." -ForegroundColor Yellow
            & takeown /f "C:\Windows.old" /r /d y 2>$null | Out-Null
            & icacls "C:\Windows.old" /grant administrators:F /t 2>$null | Out-Null
            Remove-Item -Path "C:\Windows.old" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "     [OK] C:\Windows.old removed." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "     [SKIP] Windows.old removal: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "     [SKIP] C:\Windows.old not found." -ForegroundColor DarkGray
}

# ── 6. DISM Component Store Cleanup ─────────────────────────
Write-Step "Running DISM component store cleanup (5-15 minutes) ..."

Write-Host "  -> dism /online /cleanup-image /startcomponentcleanup ..." -ForegroundColor Yellow
try {
    $proc = Start-Process -FilePath "dism.exe" `
        -ArgumentList "/online /cleanup-image /startcomponentcleanup" `
        -Wait -PassThru -ErrorAction Stop
    if ($proc.ExitCode -eq 0) {
        Write-Host "     [OK] DISM component cleanup succeeded." -ForegroundColor Green
    } else {
        Write-Host "     [WARN] DISM exited with code $($proc.ExitCode) (may be harmless)." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "     [SKIP] DISM: $($_.Exception.Message)" -ForegroundColor DarkGray
}

Write-Host "  -> dism /online /cleanup-image /analyzecomponentstore ..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "dism.exe" `
        -ArgumentList "/online /cleanup-image /analyzecomponentstore" `
        -Wait -ErrorAction Stop
    Write-Host "     [OK] DISM analysis complete." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] DISM analyze: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 7. DNS Cache flush ───────────────────────────────────────
Write-Step "Flushing DNS cache ..."

try {
    $result = & ipconfig /flushdns 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "     [OK] DNS cache flushed." -ForegroundColor Green
    } else {
        Write-Host "     [WARN] ipconfig /flushdns returned $LASTEXITCODE." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "     [SKIP] DNS flush: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 3 Complete. System cleanup finished.               " -ForegroundColor Magenta
Write-Host "  Reboot strongly recommended to finalize all changes.     " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
