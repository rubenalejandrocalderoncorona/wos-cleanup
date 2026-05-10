# wos-cleanup

**Windows Optimization & Sanitization — modular cleanup tool**

Strips bloatware, kills telemetry, tunes performance, and deep-cleans the system.
Designed to run right after a clean Windows install.

---

## How to use

1. Go to the [**Releases**](https://github.com/rubenalejandrocalderoncorona/wos-cleanup/releases/latest) page
2. Download **wos-cleanup.bat**
3. Double-click it
4. Accept the UAC (Administrator) prompt
5. Reboot when done

That's it — no extraction, no CMD, no extra steps.

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
- Internet connection (scripts are fetched from GitHub at runtime)
- Administrator privileges (auto-handled via UAC prompt)

---

## Architecture

```
wos-cleanup/
├── wos-cleanup.bat          ← Single-file launcher (download this from Releases)
└── scripts/
    ├── phase1_debloat.ps1   ← Fetched at runtime from GitHub
    ├── phase2_optimize.ps1
    └── phase3_cleanup.ps1
```

The launcher downloads each `.ps1` from this repo's `main` branch at runtime and runs them with `-ExecutionPolicy Bypass` — no manual policy changes needed.

---

## License

MIT
