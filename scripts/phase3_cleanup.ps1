# ============================================================
#  phase3_cleanup.ps1
#  Deep system cleanup:
#    1. Windows Disk Cleanup (cleanmgr) via registry sage set
#    2. Manually wipe common temp/junk folders
#    3. Clear Windows Update cache (SoftwareDistribution)
#    4. DISM component store cleanup
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

# StateFlags0001 enables each category for the /sagerun:1 preset
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
    catch { <# silently skip unknown categories #> }
}

Write-Host "  -> Launching cleanmgr /sagerun:1 (this may take a few minutes) ..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -ErrorAction Stop
    Write-Host "     [OK] Disk Cleanup completed." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] cleanmgr: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 2. Manual temp/junk folder wipe ─────────────────────────
Write-Step "Wiping temporary and junk folders ..."

Remove-FolderContents "$env:TEMP"                                    "Current User Temp (%TEMP%)"
Remove-FolderContents "C:\Windows\Temp"                              "Windows Temp (C:\Windows\Temp)"
Remove-FolderContents "C:\Windows\Prefetch"                          "Prefetch Cache"
Remove-FolderContents "$env:LOCALAPPDATA\Temp"                       "LocalAppData Temp"
Remove-FolderContents "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "IE/Edge Internet Cache"
Remove-FolderContents "$env:LOCALAPPDATA\CrashDumps"                 "Crash Dumps"
Remove-FolderContents "C:\Windows\Logs\CBS"                          "CBS Logs"
Remove-FolderContents "C:\Windows\Logs\DISM"                         "DISM Logs"

# Recycle Bin (all drives)
Write-Host "  -> Emptying Recycle Bin ..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "     [OK] Recycle Bin emptied." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Recycle Bin: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 3. Windows Update cache (SoftwareDistribution) ──────────
Write-Step "Clearing Windows Update cache (SoftwareDistribution) ..."

$wuServices = @("wuauserv", "bits", "cryptsvc", "msiserver")

Write-Host "  -> Stopping Windows Update related services ..." -ForegroundColor Yellow
foreach ($svc in $wuServices) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Write-Host "     [OK] Stopped: $svc" -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $svc : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

Remove-FolderContents "C:\Windows\SoftwareDistribution\Download"     "Windows Update Download Cache"
Remove-FolderContents "C:\Windows\SoftwareDistribution\DataStore"    "Windows Update DataStore"
Remove-FolderContents "C:\Windows\System32\catroot2"                 "Catroot2 (Windows Update metadata)"

Write-Host "  -> Restarting Windows Update related services ..." -ForegroundColor Yellow
foreach ($svc in $wuServices) {
    try {
        Start-Service -Name $svc -ErrorAction Stop
        Write-Host "     [OK] Started: $svc" -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $svc : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ── 4. DISM Component Store Cleanup ─────────────────────────
Write-Step "Running DISM component store cleanup (this can take 5-15 minutes) ..."

Write-Host "  -> dism /online /cleanup-image /startcomponentcleanup ..." -ForegroundColor Yellow
try {
    $dismArgs = "/online /cleanup-image /startcomponentcleanup"
    $proc = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -PassThru -ErrorAction Stop
    if ($proc.ExitCode -eq 0) {
        Write-Host "     [OK] DISM component cleanup succeeded." -ForegroundColor Green
    } else {
        Write-Host "     [WARN] DISM exited with code $($proc.ExitCode) (may be harmless)." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "     [SKIP] DISM: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Optional: Analyze health to confirm store is clean
Write-Host "  -> dism /online /cleanup-image /analyzecomponentstore ..." -ForegroundColor Yellow
try {
    Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /analyzecomponentstore" -Wait -ErrorAction Stop
    Write-Host "     [OK] DISM analysis complete." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] DISM analyze: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── 5. DNS Cache flush ───────────────────────────────────────
Write-Step "Flushing DNS cache ..."
try {
    ipconfig /flushdns | Out-Null
    Write-Host "     [OK] DNS cache flushed." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] DNS flush: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 3 Complete. System cleanup finished.               " -ForegroundColor Magenta
Write-Host "  A reboot is strongly recommended to finalize all changes. " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
