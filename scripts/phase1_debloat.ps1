# ============================================================
#  phase1_debloat.ps1
#  Aggressively removes pre-installed Windows bloatware and
#  unnecessary UWP (AppX) packages for the current user
#  and the system provisioned image.
#
#  Goal: clean baseline — only fundamental Windows components
#  remain. User installs what they actually need afterwards.
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
        Get-AppxPackage -Name $PackagePattern -AllUsers -ErrorAction SilentlyContinue |
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageName -like "*$PackagePattern*" } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
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
Remove-AppxSafe "Microsoft.XboxGamingOverlay"          "Xbox Gaming Overlay / Game Bar"
Remove-AppxSafe "Microsoft.XboxIdentityProvider"       "Xbox Identity Provider"
Remove-AppxSafe "Microsoft.XboxSpeechToTextOverlay"    "Xbox Speech-to-Text Overlay"
Remove-AppxSafe "Microsoft.Xbox.TCUI"                  "Xbox TCUI"
Remove-AppxSafe "Microsoft.GamingApp"                  "Xbox Gaming App (Win11)"
Remove-AppxSafe "Microsoft.GamingServices"             "Gaming Services"
Remove-AppxSafe "Microsoft.ZuneMusic"                  "Groove Music / Zune Music"
Remove-AppxSafe "Microsoft.ZuneVideo"                  "Movies & TV / Zune Video"
Remove-AppxSafe "Microsoft.MicrosoftSolitaireCollection" "Microsoft Solitaire Collection"
Remove-AppxSafe "king.com.CandyCrushSaga"              "Candy Crush Saga"
Remove-AppxSafe "king.com.CandyCrushSodaSaga"          "Candy Crush Soda Saga"
Remove-AppxSafe "king.com.BubbleWitch3Saga"            "Bubble Witch 3 Saga"
Remove-AppxSafe "Facebook.Facebook"                    "Facebook"
Remove-AppxSafe "SpotifyAB.SpotifyMusic"               "Spotify (pre-installed)"
Remove-AppxSafe "Disney.37853D22215B2"                 "Disney+"
Remove-AppxSafe "AmazonVideo.PrimeVideo"               "Amazon Prime Video"
Remove-AppxSafe "TikTok.TikTok"                        "TikTok"

# ── 3D & Mixed Reality ───────────────────────────────────────
Write-Step "Removing 3D and Mixed Reality components ..."

Remove-AppxSafe "Microsoft.Microsoft3DViewer"          "3D Viewer"
Remove-AppxSafe "Microsoft.3DBuilder"                  "3D Builder"
Remove-AppxSafe "Microsoft.Print3D"                    "Print 3D"
Remove-AppxSafe "Microsoft.MixedReality.Portal"        "Mixed Reality Portal"

# ── Cortana & Copilot ────────────────────────────────────────
Write-Step "Removing Cortana and Copilot ..."

Remove-AppxSafe "Microsoft.549981C3F5F10"              "Cortana (Win10/11 UWP)"
Remove-AppxSafe "Microsoft.Windows.Ai.Copilot.Provider" "Copilot Provider"
Remove-AppxSafe "MicrosoftWindows.Client.Copilot"      "Windows Copilot"
Remove-AppxSafe "Microsoft.Copilot"                    "Microsoft Copilot"

# ── Communication & Social ───────────────────────────────────
Write-Step "Removing bundled communication apps ..."

Remove-AppxSafe "microsoft.windowscommunicationsapps"  "Mail and Calendar"
Remove-AppxSafe "Microsoft.People"                     "People"
Remove-AppxSafe "Microsoft.YourPhone"                  "Your Phone / Phone Link"
Remove-AppxSafe "Microsoft.Phone"                      "Phone Link (Win11)"
Remove-AppxSafe "MicrosoftTeams"                       "Microsoft Teams (personal, pre-installed)"
Remove-AppxSafe "MSTeams"                              "Microsoft Teams 2.0 (Win11 built-in)"
Remove-AppxSafe "Microsoft.Getskype"                   "Get Skype"
Remove-AppxSafe "Microsoft.SkypeApp"                   "Skype"

# ── News, Weather & Finance ──────────────────────────────────
Write-Step "Removing news, weather, and finance apps ..."

Remove-AppxSafe "Microsoft.BingNews"                   "Microsoft News"
Remove-AppxSafe "Microsoft.BingWeather"                "Microsoft Weather"
Remove-AppxSafe "Microsoft.BingFinance"                "Bing Finance"
Remove-AppxSafe "Microsoft.BingSports"                 "Bing Sports"
Remove-AppxSafe "Microsoft.BingTranslator"             "Bing Translator"
Remove-AppxSafe "Microsoft.MSN.Money"                  "MSN Money"
Remove-AppxSafe "Microsoft.MSN.Travel"                 "MSN Travel"
Remove-AppxSafe "Microsoft.MSN.News"                   "MSN News"
Remove-AppxSafe "Microsoft.MSN.Sports"                 "MSN Sports"
Remove-AppxSafe "Microsoft.MSN.Weather"                "MSN Weather"

# ── Maps & Travel ────────────────────────────────────────────
Write-Step "Removing Maps and travel apps ..."

Remove-AppxSafe "Microsoft.WindowsMaps"                "Windows Maps"
Remove-AppxSafe "Microsoft.GetHelp"                    "Get Help"
Remove-AppxSafe "Microsoft.Getstarted"                 "Tips / Get Started"
Remove-AppxSafe "Microsoft.Todos"                      "Microsoft To Do"

# ── Productivity & Office Ads ────────────────────────────────
Write-Step "Removing pre-installed productivity junk ..."

Remove-AppxSafe "Microsoft.MicrosoftOfficeHub"         "Office Hub (ads)"
Remove-AppxSafe "Microsoft.Office.OneNote"             "OneNote (pre-installed)"
Remove-AppxSafe "Microsoft.Office.Lens.16"             "Office Lens"
Remove-AppxSafe "Microsoft.PowerAutomateDesktop"       "Power Automate Desktop"
Remove-AppxSafe "Microsoft.Whiteboard"                 "Microsoft Whiteboard"
Remove-AppxSafe "MicrosoftCorporationII.MicrosoftFamily" "Microsoft Family Safety"
Remove-AppxSafe "Microsoft.MicrosoftJournal"           "Microsoft Journal"
Remove-AppxSafe "Microsoft.WindowsNotepad"             "Notepad (Store version)"

# ── Media & Camera ───────────────────────────────────────────
Write-Step "Removing camera and media extras ..."

# WindowsCamera kept: only built-in webcam app; removing leaves no default.
# ScreenSketch (Snipping Tool) kept: Win+Shift+S shortcut depends on it.
# Windows.Photos kept: only default image viewer; removing breaks double-click on images.
# WindowsNotepad kept: on Win11 this IS Notepad; removing it leaves no text editor.
Remove-AppxSafe "Microsoft.WindowsSoundRecorder"       "Voice Recorder / Sound Recorder"
Remove-AppxSafe "Microsoft.Clipchamp"                  "Clipchamp Video Editor"
Remove-AppxSafe "Clipchamp.Clipchamp"                  "Clipchamp (alternate package name)"
Remove-AppxSafe "Microsoft.MSPaint"                    "Paint 3D (legacy)"

# ── Feedback & Dev ───────────────────────────────────────────
Write-Step "Removing feedback and developer preview apps ..."

Remove-AppxSafe "Microsoft.WindowsFeedbackHub"         "Feedback Hub"
# WindowsTerminal kept: default terminal host on Win11; removing reverts all shells to conhost.
Remove-AppxSafe "Microsoft.DevHome"                    "Dev Home (Win11)"
Remove-AppxSafe "Microsoft.DevHomeGitHubExtension"    "Dev Home GitHub Extension"

# ── OEM Bloatware — Common Brands ────────────────────────────
Write-Step "Removing common OEM bloatware ..."

# HP
Remove-AppxSafe "HPInc.MyHPGaming"                      "HP Gaming Hub"
Remove-AppxSafe "AD2F1837.HPPCHardwareDiagnosticsWindows" "HP Diagnostics"
Remove-AppxSafe "AD2F1837.HPJumpStarts"                  "HP Jump Starts"
Remove-AppxSafe "AD2F1837.HPPowerManager"                "HP Power Manager"
Remove-AppxSafe "AD2F1837.myHP"                          "My HP"

# Dell
Remove-AppxSafe "DellInc.DellSupportAssistforPCs"       "Dell SupportAssist"
Remove-AppxSafe "DellInc.DellCommandUpdate"             "Dell Command Update"
Remove-AppxSafe "DellInc.DellDigitalDelivery"           "Dell Digital Delivery"
Remove-AppxSafe "DellInc.PartnerPromo"                  "Dell Partner Promo"
Remove-AppxSafe "DellInc.DellOptimizer"                 "Dell Optimizer"

# Lenovo
Remove-AppxSafe "LenovoCompanyLimited.LenovoCompanion"  "Lenovo Companion"
Remove-AppxSafe "E046963F.LenovoSettingsforEnterprise"  "Lenovo Settings"
Remove-AppxSafe "LenovoCompanyLimited.LenovoID"         "Lenovo ID"
Remove-AppxSafe "E046963F.LenovoSystemInterface"        "Lenovo System Interface Foundation"

# Acer
Remove-AppxSafe "AcerIncorporated.AcerCare"             "Acer Care Center"
Remove-AppxSafe "AcerIncorporated.QuickAccess"          "Acer Quick Access"

# ASUS
Remove-AppxSafe "ASUSTeKCOMPUTERINC.MyASUS"             "MyASUS"
Remove-AppxSafe "ASUSTeKCOMPUTERINC.ASUSSystemControl"  "ASUS System Control"

# Samsung
Remove-AppxSafe "SAMSUNGELECTRONICSCO.LTD.SamsungSettings" "Samsung Settings"
Remove-AppxSafe "SAMSUNGELECTRONICSCO.LTD.SamsungUpdate"   "Samsung Update"

# MSI
Remove-AppxSafe "MSIGroup.MsiCenter"                    "MSI Center"

# ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Phase 1 Complete. Bloatware removal finished.            " -ForegroundColor Magenta
Write-Host "  Recommendation: Reboot before running Phase 2.           " -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
