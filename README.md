# wos-cleanup

**Windows Optimization & Sanitization — modular cleanup tool**

Strips bloatware, kills telemetry, tunes performance, and deep-cleans the system.
Designed to run right after a clean Windows install.

---

## How to run

### Step 1 — Open CMD as Administrator

Press **Win**, type `cmd`, then right-click **Command Prompt** → **Run as administrator**.

> The tool auto-elevates if you forget — but starting as admin avoids the UAC prompt.

---

### Step 2 — Navigate to the folder

```cmd
cd C:\path\to\wos-cleanup
```

Replace `C:\path\to\wos-cleanup` with wherever you saved this folder.
Example: if you downloaded it to your Desktop:

```cmd
cd %USERPROFILE%\Desktop\wos-cleanup
```

---

### Step 3 — Run the phases

Run all three phases back-to-back (recommended):

```cmd
wos-cleanup.bat phase all
```

Or run them one at a time with a reboot between each:

```cmd
wos-cleanup.bat phase 1
```
*(reboot)*
```cmd
wos-cleanup.bat phase 2
```
*(reboot)*
```cmd
wos-cleanup.bat phase 3
```
*(reboot)*

---

## What each phase does

| Phase | What it does |
|-------|-------------|
| **1 — Debloat** | Removes pre-installed UWP junk: Xbox, Cortana, Copilot, Teams, Candy Crush, Clipchamp, Skype, OEM apps (Dell/HP/Lenovo/ASUS/Samsung/MSI), and more. Keeps only what the OS actually needs. |
| **2 — Optimize** | Disables telemetry, disables unnecessary background services, turns off Game DVR/Game Bar, applies Ultimate Performance power plan (High Performance on Home editions), disables Nagle's algorithm per adapter, strips taskbar widgets and Start Menu Bing search. |
| **3 — Cleanup** | Wipes all temp/prefetch/crash folders, clears Windows Update cache, clears browser caches (Edge, Chrome, Firefox, Brave), removes Windows.old if present, runs DISM component cleanup, flushes DNS. |

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built-in — nothing to install)
- Administrator privileges (auto-handled by the launcher)

---

## Architecture

```
wos-cleanup/
├── wos-cleanup.bat          ← Entry point (auto-elevates, dispatches phases)
└── scripts/
    ├── phase1_debloat.ps1
    ├── phase2_optimize.ps1
    └── phase3_cleanup.ps1
```

The `.bat` calls each `.ps1` with `-ExecutionPolicy Bypass` — no manual policy changes needed.

---

## License

MIT
