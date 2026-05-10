# ============================================================
#  phase2_optimize.ps1
#  Disables Windows telemetry, kills unnecessary background
#  services, and tunes visual/performance/network settings
#  for a clean, fast baseline.
#
#  Safe to run on Windows 10/11 (Home, Pro, Enterprise).
#  All changes are reversible via Services.msc and regedit.
#  Run as Administrator. Reboot after completion.
# ============================================================

$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string]$Message)
    Write-Host "`n[PHASE 2] $Message" -ForegroundColor Cyan
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Host "     [OK] $Path\$Name = $Value" -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $Path\$Name : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

function Disable-ServiceSafe {
    param([string]$ServiceName, [string]$FriendlyName)
    Write-Host "  -> Disabling service: $FriendlyName ($ServiceName)" -ForegroundColor Yellow
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction Stop
        if ($svc.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
        Write-Host "     [OK] $FriendlyName disabled." -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $FriendlyName : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  WOS-Cleanup  |  Phase 2  -  Optimize                       " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

# -- Telemetry & Data Collection ------------------------------
Write-Step "Disabling Windows telemetry and data collection ..."

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 0

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 1

Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0

Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
# PeriodInNanoSeconds must be deleted (not zeroed)  -  a value of 0 means "evaluate constantly"
try {
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Force -ErrorAction SilentlyContinue
    Write-Host "     [OK] PeriodInNanoSeconds deleted." -ForegroundColor Green
}
catch { }

Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0

# Disable Copilot
Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1

# Disable Windows Error Reporting
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "Disabled" 1

# Disable Recall / Snapshots (Win11 24H2+)
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1

# -- Telemetry Services ---------------------------------------
Write-Step "Disabling telemetry and tracking services ..."

Disable-ServiceSafe "DiagTrack"               "Connected User Experiences and Telemetry"
Disable-ServiceSafe "dmwappushservice"         "WAP Push Message Routing Service"
Disable-ServiceSafe "PcaSvc"                  "Program Compatibility Assistant"
Disable-ServiceSafe "RemoteRegistry"          "Remote Registry"
Disable-ServiceSafe "WerSvc"                  "Windows Error Reporting"
Disable-ServiceSafe "wisvc"                   "Windows Insider Service"
Disable-ServiceSafe "RetailDemo"              "Retail Demo Service"
Disable-ServiceSafe "diagsvc"                 "Diagnostic Execution Service"
# WdiServiceHost and WdiSystemHost NOT disabled: they power the network troubleshooter wizard
# which is a visible OS repair tool users rely on.

# -- Unnecessary Background Services -------------------------
Write-Step "Disabling unnecessary background services ..."

Disable-ServiceSafe "Fax"                     "Fax Service"
Disable-ServiceSafe "MapsBroker"              "Downloaded Maps Manager"
Disable-ServiceSafe "lfsvc"                   "Geolocation Service"
Disable-ServiceSafe "WMPNetworkSvc"           "Windows Media Player Network Sharing"
Disable-ServiceSafe "XblAuthManager"          "Xbox Live Auth Manager"
Disable-ServiceSafe "XblGameSave"             "Xbox Live Game Save"
Disable-ServiceSafe "XboxNetApiSvc"           "Xbox Live Networking Service"
Disable-ServiceSafe "XboxGipSvc"              "Xbox Accessory Management"
Disable-ServiceSafe "TermService"             "Remote Desktop Services"
Disable-ServiceSafe "UmRdpService"            "Remote Desktop Services UserMode Port Redirector"
# SessionEnv NOT disabled: dependency of Group Policy client on domain machines; breaks logins.
# TrkWks NOT disabled: its absence causes shell shortcuts to broken files to stop auto-resolving.
# stisvc NOT disabled: required by all TWAIN scanners (HP/Epson/Canon/Brother).
# icssvc NOT disabled: Mobile Hotspot  -  useful feature, no perf impact when idle.
# PhoneSvc NOT disabled: drives Bluetooth HFP call audio on headsets.
# tabletinputservice NOT disabled: breaks touch/pen input on all touchscreen hardware.

# WSearch: disable only on confirmed SSD (safe to disable there; hurts HDDs significantly)
Write-Host "`n[PHASE 2] Checking storage type before disabling Windows Search ..." -ForegroundColor Cyan
try {
    $diskType = Get-PhysicalDisk -ErrorAction SilentlyContinue |
                    Where-Object { $_.DeviceId -eq 0 } |
                    Select-Object -ExpandProperty MediaType
    if ($diskType -eq 'SSD' -or $diskType -eq 'NVMe') {
        Disable-ServiceSafe "WSearch" "Windows Search indexing (SSD confirmed  -  safe to disable)"
    } else {
        Write-Host "     [SKIP] WSearch kept  -  storage type '$diskType' is not SSD (disabling on HDD degrades performance)." -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "     [SKIP] WSearch storage check failed: $($_.Exception.Message)  -  leaving enabled." -ForegroundColor DarkGray
}

# SysMain (Superfetch): disable only on SSD  -  critical for HDD boot/launch performance
Write-Host "`n[PHASE 2] Checking storage type before disabling SysMain ..." -ForegroundColor Cyan
try {
    $diskType = Get-PhysicalDisk -ErrorAction SilentlyContinue |
                    Where-Object { $_.DeviceId -eq 0 } |
                    Select-Object -ExpandProperty MediaType
    if ($diskType -eq 'SSD' -or $diskType -eq 'NVMe') {
        Disable-ServiceSafe "SysMain" "SysMain / Superfetch (SSD confirmed  -  safe to disable)"
    } else {
        Write-Host "     [SKIP] SysMain kept  -  storage type '$diskType' is not SSD (disabling on HDD causes slow boots)." -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "     [SKIP] SysMain storage check failed: $($_.Exception.Message)  -  leaving enabled." -ForegroundColor DarkGray
}

# -- Game DVR / Game Bar --------------------------------------
Write-Step "Disabling Game DVR and Game Bar overlays ..."

Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\GameBar" "UseNexusForGameBarEnabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\GameBar" "AutoGameModeEnabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" 0

# -- Explorer & Shell Usability Tweaks -----------------------
Write-Step "Applying Explorer usability improvements ..."

# Show file extensions
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

# Show hidden files and folders
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1

# Show protected OS files (set to 1 to hide  -  keep default, just ensure extensions visible)
# Do NOT set ShowSuperHidden to 1 (shows Windows system files  -  risky for casual use)

# Open File Explorer to This PC instead of Quick Access
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1

# Disable News and Interests (taskbar widget feed)
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2

# Disable Start Menu web/Bing suggestions
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1

# Restore full right-click context menu (Windows 11  -  removes the simplified menu)
# Must use New-Item + Set-Item to correctly set the (default) value; Set-ItemProperty is unreliable for this.
try {
    $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (-not (Test-Path $clsidPath)) {
        New-Item -Path $clsidPath -Force | Out-Null
    }
    Set-Item -Path $clsidPath -Value "" -Force -ErrorAction Stop
    Write-Host "     [OK] Win11 full context menu restored." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Context menu restore: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Disable Lock Screen (skip to login)
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1

# Disable Taskbar Chat (Teams icon on taskbar  -  Win11)
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0

# Disable Taskbar Widgets button (Win11)
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0

# -- Visual Performance Tweaks --------------------------------
Write-Step "Optimizing visual settings for performance ..."

Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 3

Set-RegistryValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"

Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0

Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0

# Reduce mouse hover time
Set-RegistryValue "HKCU:\Control Panel\Mouse" "MouseHoverTime" "100" "String"

# -- Network / TCP-IP Tweaks ----------------------------------
Write-Step "Applying network and TCP/IP performance tweaks ..."

# Nagle's algorithm must be disabled per-adapter (global Parameters path is ignored on Vista+).
# We iterate every active adapter GUID and write the keys under each interface subkey.
Write-Host "  -> Disabling Nagle's algorithm on all active network adapters ..." -ForegroundColor Yellow
try {
    $ifacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    $adapterGuids = Get-ChildItem -Path $ifacesPath -ErrorAction Stop |
                        Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DhcpIPAddress -or
                                       (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).IPAddress }
    if (-not $adapterGuids) {
        # Fallback: apply to all interface subkeys regardless of IP assignment
        $adapterGuids = Get-ChildItem -Path $ifacesPath -ErrorAction Stop
    }
    foreach ($iface in $adapterGuids) {
        Set-RegistryValue $iface.PSPath "TcpAckFrequency" 1
        Set-RegistryValue $iface.PSPath "TCPNoDelay" 1
        Set-RegistryValue $iface.PSPath "TcpDelAckTicks" 0
    }
    Write-Host "     [OK] Nagle disabled on $($adapterGuids.Count) adapter(s)." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Nagle per-adapter: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# TCP receive window auto-tuning: 'normal' is the safe default (better than 'disabled' for modern networks)
try {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    Write-Host "     [OK] TCP auto-tuning set to normal." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] TCP auto-tuning: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# DNS negative cache: keep at default (a few seconds) to avoid hammering failed lookups.
# MaxCacheTtl left at Windows default (86400)  -  no registry override needed.

# -- Power Plan  -  Ultimate Performance -----------------------
Write-Step "Activating Ultimate Performance power plan ..."

try {
    # Ultimate Performance is available on Pro/Enterprise/Education/Workstation  -  not on Home.
    # duplicatescheme may silently return nothing on Home SKUs, so we verify after the call.
    $existingGuid = (powercfg /list | Select-String "Ultimate Performance") -replace ".*GUID: ([a-f0-9-]+).*", '$1'
    if (-not $existingGuid) {
        powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null
        $existingGuid = (powercfg /list | Select-String "Ultimate Performance") -replace ".*GUID: ([a-f0-9-]+).*", '$1'
    }
    if ($existingGuid) {
        $guid = $existingGuid.Trim()
        powercfg /setactive $guid
        Write-Host "     [OK] Ultimate Performance plan activated. GUID: $guid" -ForegroundColor Green
    } else {
        Write-Host "     [INFO] Ultimate Performance plan not available on this Windows edition (requires Pro/Enterprise)." -ForegroundColor Yellow
        Write-Host "     [INFO] Falling back to High Performance plan ..." -ForegroundColor Yellow
        $hpGuid = (powercfg /list | Select-String "High performance") -replace ".*GUID: ([a-f0-9-]+).*", '$1'
        if ($hpGuid) {
            powercfg /setactive $hpGuid.Trim()
            Write-Host "     [OK] High Performance plan activated. GUID: $($hpGuid.Trim())" -ForegroundColor Green
        } else {
            Write-Host "     [SKIP] Neither Ultimate Performance nor High Performance plan found." -ForegroundColor DarkGray
        }
    }
}
catch {
    Write-Host "     [SKIP] Power plan: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Disable hibernation (frees hiberfil.sys)
try {
    powercfg /h off
    Write-Host "     [OK] Hibernation disabled (hiberfil.sys freed)." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Hibernation: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Disable Fast Startup (can cause update/dual-boot issues; true shutdown is cleaner)
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0

# -- Startup Programs (common nuisances via registry) --------
Write-Step "Removing common startup nuisances from registry ..."

$startupKeys = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
$removeFromStartup = @(
    "OneDrive",
    "Spotify",
    "Discord",
    "EpicGamesLauncher",
    "Steam",
    "Teams",
    "MicrosoftTeams",
    "Cortana",
    "GameBarPresenceWriter",
    "Microsoft Edge",
    "MicrosoftEdgeAutoLaunch",
    "SkypeApp"
)

foreach ($key in $startupKeys) {
    foreach ($entry in $removeFromStartup) {
        try {
            if (Get-ItemProperty -Path $key -Name $entry -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $key -Name $entry -Force -ErrorAction Stop
                Write-Host "     [OK] Removed startup: $entry from $key" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "     [SKIP] Startup $entry : $($_.Exception.Message)" -ForegroundColor DarkGray
        }
    }
}

# -- Disable Auto-Restart After Updates ----------------------
Write-Step "Preventing Windows Update forced auto-restarts ..."

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUPowerManagement" 0

# Disable Windows Update P2P delivery  -  value 0 = HTTP only (Microsoft servers only, no peer sharing)
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0

# ------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 2 Complete. Optimization settings applied.         " -ForegroundColor Magenta
Write-Host "  Recommendation: Reboot before running Phase 3.           " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
