# ============================================================
#  phase1_debloat.ps1
#  Aggressively removes pre-installed Windows bloatware and
#  unnecessary UWP (AppX) packages for the current user
#  and the system provisioned image.
# ============================================================

$ErrorActionPreference = 'Continue'

function Write-Step {
    param([string]$Message)
    Write-Host "`n[PHASE 1] $Message" -ForegroundColor Cyan
}

function Remove-AppxSafe {
    param(
        [string]$PackagePattern,
        [string]$FriendlyName
    )
    Write-Host "  -> Removing: $FriendlyName" -ForegroundColor Yellow
    try {
        # Remove for current user
        Get-AppxPackage -Name $PackagePattern -ErrorAction SilentlyContinue |
            Remove-AppxPackage -ErrorAction Stop
        # Remove provisioned (prevents reinstall for new users)
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageName -like "*$PackagePattern*" } |
            Remove-AppxProvisionedPackage -Online -ErrorAction Stop
        Write-Host "     [OK] $FriendlyName removed." -ForegroundColor Green
    }
    catch {
        Write-Host "     [SKIP] $FriendlyName : $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  WOS-Cleanup  |  Phase 1 — Debloat                        " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta

# ── Gaming & Entertainment ───────────────────────────────────
Write-Step "Removing gaming and entertainment bloatware ..."

Remove-AppxSafe "Microsoft.XboxApp"                    "Xbox App"
Remove-AppxSafe "Microsoft.XboxGameOverlay"            "Xbox Game Overlay"
Remove-AppxSafe "Microsoft.XboxGamingOverlay"          "Xbox Gaming Overlay (Game Bar)"
Remove-AppxSafe "Microsoft.XboxIdentityProvider"       "Xbox Identity Provider"
Remove-AppxSafe "Microsoft.XboxSpeechToTextOverlay"    "Xbox Speech-to-Text Overlay"
Remove-AppxSafe "Microsoft.Xbox.TCUI"                  "Xbox TCUI"
Remove-AppxSafe "Microsoft.GamingApp"                  "Xbox Gaming App (Win11)"
Remove-AppxSafe "Microsoft.ZuneMusic"                  "Groove Music / Zune Music"
Remove-AppxSafe "Microsoft.ZuneVideo"                  "Movies & TV / Zune Video"
Remove-AppxSafe "Microsoft.MicrosoftSolitaireCollection" "Microsoft Solitaire Collection"
Remove-AppxSafe "king.com.CandyCrushSaga"              "Candy Crush Saga"
Remove-AppxSafe "king.com.CandyCrushSodaSaga"          "Candy Crush Soda Saga"
Remove-AppxSafe "king.com.BubbleWitch3Saga"            "Bubble Witch 3 Saga"
Remove-AppxSafe "Facebook.Facebook"                    "Facebook"
Remove-AppxSafe "SpotifyAB.SpotifyMusic"               "Spotify (pre-installed)"

# ── 3D & Mixed Reality ───────────────────────────────────────
Write-Step "Removing 3D and Mixed Reality components ..."

Remove-AppxSafe "Microsoft.Microsoft3DViewer"          "3D Viewer"
Remove-AppxSafe "Microsoft.3DBuilder"                  "3D Builder"
Remove-AppxSafe "Microsoft.Print3D"                    "Print 3D"
Remove-AppxSafe "Microsoft.MixedReality.Portal"        "Mixed Reality Portal"

# ── Cortana & Search ─────────────────────────────────────────
Write-Step "Removing Cortana ..."

Remove-AppxSafe "Microsoft.549981C3F5F10"              "Cortana (Win10/11 UWP)"

# ── Communication & Social ───────────────────────────────────
Write-Step "Removing bundled communication apps ..."

Remove-AppxSafe "microsoft.windowscommunicationsapps"  "Mail and Calendar"
Remove-AppxSafe "Microsoft.People"                     "People"
Remove-AppxSafe "Microsoft.YourPhone"                  "Your Phone / Phone Link"
Remove-AppxSafe "MicrosoftTeams"                       "Microsoft Teams (personal, pre-installed)"
Remove-AppxSafe "Microsoft.Getskype"                   "Get Skype"

# ── News, Weather & Finance ──────────────────────────────────
Write-Step "Removing news, weather, and finance apps ..."

Remove-AppxSafe "Microsoft.BingNews"                   "Microsoft News"
Remove-AppxSafe "Microsoft.BingWeather"                "Microsoft Weather"
Remove-AppxSafe "Microsoft.BingFinance"                "Bing Finance"
Remove-AppxSafe "Microsoft.BingSports"                 "Bing Sports"
Remove-AppxSafe "Microsoft.BingTranslator"             "Bing Translator"

# ── Maps & Travel ────────────────────────────────────────────
Write-Step "Removing Maps and travel apps ..."

Remove-AppxSafe "Microsoft.WindowsMaps"                "Windows Maps"
Remove-AppxSafe "Microsoft.GetHelp"                    "Get Help"
Remove-AppxSafe "Microsoft.Getstarted"                 "Tips / Get Started"
Remove-AppxSafe "Microsoft.Todos"                      "Microsoft To Do"

# ── Camera, Photos extras ────────────────────────────────────
Write-Step "Removing camera and photo extras ..."

Remove-AppxSafe "Microsoft.WindowsCamera"              "Windows Camera"
Remove-AppxSafe "Microsoft.WindowsSoundRecorder"       "Voice Recorder"
Remove-AppxSafe "Microsoft.WindowsFeedbackHub"         "Feedback Hub"
Remove-AppxSafe "Microsoft.MicrosoftOfficeHub"         "Office Hub (ads)"
Remove-AppxSafe "Microsoft.Office.OneNote"             "OneNote (pre-installed)"
Remove-AppxSafe "Microsoft.SkypeApp"                   "Skype"
Remove-AppxSafe "Microsoft.PowerAutomateDesktop"       "Power Automate Desktop"
Remove-AppxSafe "Microsoft.Whiteboard"                 "Microsoft Whiteboard"
Remove-AppxSafe "Microsoft.MSPaint"                    "Paint 3D (legacy)"
Remove-AppxSafe "Microsoft.ScreenSketch"               "Snip & Sketch (legacy)"

# ── OEM Common Bloatware ─────────────────────────────────────
Write-Step "Removing common OEM bloatware ..."

Remove-AppxSafe "HPInc.MyHPGaming"                     "HP Gaming Hub"
Remove-AppxSafe "AD2F1837.HPPCHardwareDiagnosticsWindows" "HP Diagnostics"
Remove-AppxSafe "DellInc.DellSupportAssistforPCs"      "Dell SupportAssist"
Remove-AppxSafe "DellInc.DellCommandUpdate"            "Dell Command Update"
Remove-AppxSafe "DellInc.DellDigitalDelivery"          "Dell Digital Delivery"
Remove-AppxSafe "LenovoCompanyLimited.LenovoCompanion" "Lenovo Companion"
Remove-AppxSafe "AcerIncorporated.AcerCare"            "Acer Care Center"

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 1 Complete. Bloatware removal finished.            " -ForegroundColor Magenta
Write-Host "  Recommendation: Reboot before running Phase 2.           " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
