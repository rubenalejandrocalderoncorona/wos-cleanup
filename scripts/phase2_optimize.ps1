# ============================================================
#  phase2_optimize.ps1
#  Disables Windows telemetry, kills unnecessary background
#  services, and tunes visual/performance settings.
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
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        }
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
        Write-Host "     [OK] $FriendlyName disabled." -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $FriendlyName : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  WOS-Cleanup  |  Phase 2 — Optimize                       " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

# ── Telemetry & Data Collection ──────────────────────────────
Write-Step "Disabling Windows telemetry and data collection ..."

# Telemetry level: 0 = Security (Enterprise) / 1 = Basic
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "MaxTelemetryAllowed" 0

# Disable Customer Experience Improvement Program (CEIP)
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0

# Disable Application Telemetry
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 1

# Disable Advertising ID
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1

# Disable Activity History / Timeline
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0

# Disable Feedback notifications
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "PeriodInNanoSeconds" 0

# Disable Bing Search in Start Menu
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "CortanaConsent" 0

# ── Telemetry Services ───────────────────────────────────────
Write-Step "Disabling telemetry and tracking services ..."

Disable-ServiceSafe "DiagTrack"               "Connected User Experiences and Telemetry"
Disable-ServiceSafe "dmwappushservice"         "WAP Push Message Routing Service"
Disable-ServiceSafe "PcaSvc"                  "Program Compatibility Assistant"
Disable-ServiceSafe "RemoteRegistry"          "Remote Registry"
Disable-ServiceSafe "WerSvc"                  "Windows Error Reporting"
Disable-ServiceSafe "wisvc"                   "Windows Insider Service"
Disable-ServiceSafe "RetailDemo"              "Retail Demo Service"

# ── Unnecessary Background Services ─────────────────────────
Write-Step "Disabling unnecessary background services ..."

Disable-ServiceSafe "Fax"                     "Fax Service"
Disable-ServiceSafe "MapsBroker"              "Downloaded Maps Manager"
Disable-ServiceSafe "lfsvc"                   "Geolocation Service"
Disable-ServiceSafe "WSearch"                 "Windows Search (indexing)"
Disable-ServiceSafe "SysMain"                 "SysMain / Superfetch (SSD systems)"
Disable-ServiceSafe "XblAuthManager"          "Xbox Live Auth Manager"
Disable-ServiceSafe "XblGameSave"             "Xbox Live Game Save"
Disable-ServiceSafe "XboxNetApiSvc"           "Xbox Live Networking Service"
Disable-ServiceSafe "XboxGipSvc"              "Xbox Accessory Management"

# ── Visual Performance Tweaks ────────────────────────────────
Write-Step "Optimizing visual settings for performance ..."

# Set to "Adjust for best performance" (value 2 = custom, value 3 = best performance)
try {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-RegistryValue $path "VisualFXSetting" 3
}
catch {
    Write-Host "     [SKIP] VisualFXSetting: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Disable Animations
Set-RegistryValue "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) "Binary"

# Disable Transparency Effects
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0

# Disable Show Shadows Under Windows
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0

# ── Power Plan ───────────────────────────────────────────────
Write-Step "Switching to High Performance power plan ..."

try {
    $guid = (powercfg /list | Select-String "High performance") -replace ".*GUID: ([a-f0-9-]+).*", '$1'
    if ($guid) {
        powercfg /setactive $guid
        Write-Host "     [OK] High Performance plan activated. GUID: $guid" -ForegroundColor Green
    } else {
        Write-Host "     [SKIP] High Performance plan not found (may already be active or unlisted)." -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "     [SKIP] Power plan: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Disable hibernation (frees hiberfil.sys disk space)
try {
    powercfg /h off
    Write-Host "     [OK] Hibernation disabled (hiberfil.sys freed)." -ForegroundColor Green
}
catch {
    Write-Host "     [SKIP] Hibernation: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# ── Startup Programs (common nuisances via registry) ────────
Write-Step "Removing common startup nuisances from registry ..."

$startupKeys = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
$removeFromStartup = @("OneDrive", "Spotify", "Discord", "EpicGamesLauncher", "Steam")

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

# ── Disable Auto-Restart After Updates ──────────────────────
Write-Step "Preventing Windows Update forced auto-restarts ..."

Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUPowerManagement" 0

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 2 Complete. Optimization settings applied.         " -ForegroundColor Magenta
Write-Host "  Recommendation: Reboot before running Phase 3.           " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
