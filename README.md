# wos-cleanup

**Windows Optimization & Sanitization — modular cleanup tool**

A `.bat` launcher + PowerShell architecture that strips bloatware, kills telemetry, tunes performance, and deep-cleans the system. Designed to run right after a clean Windows install or hard reset.

---

## Quick Start

1. **Download or clone** this repository to any folder on your Windows machine.
2. Open **Command Prompt as Administrator** (or just double-click — the launcher auto-elevates).
3. Run a phase:

```cmd
wos-cleanup.bat phase 1
wos-cleanup.bat phase 2
wos-cleanup.bat phase 3
```

> You can also invoke it via `start`:
> ```cmd
> start wos-cleanup phase 1
> ```

---

## Phases

| Phase | Command | What it does |
|-------|---------|--------------|
| **1** | `wos-cleanup.bat phase 1` | **Debloat** — Removes Xbox, Cortana, Candy Crush, 3D Viewer, Mail, Teams, OEM apps, and dozens of other pre-installed UWP packages via `Get-AppxPackage`. |
| **2** | `wos-cleanup.bat phase 2` | **Optimize** — Disables DiagTrack telemetry, advertising ID, activity history, unnecessary services (SysMain, Xbox Live, Fax, Maps, etc.), applies High Performance power plan, strips visual bloat. |
| **3** | `wos-cleanup.bat phase 3` | **Cleanup** — Runs `cleanmgr /sagerun:1`, wipes all temp/prefetch/crash folders, clears the Windows Update `SoftwareDistribution` cache, and runs `dism /cleanup-image /startcomponentcleanup`. |

**Recommended order:** Run phases in sequence (1 → 2 → 3), rebooting between each phase for cleanest results.

---

## Architecture

```
wos-cleanup/
├── wos-cleanup.bat          ← Entry point (auto-elevates, dispatches phases)
└── scripts/
    ├── phase1_debloat.ps1   ← AppX / UWP bloatware removal
    ├── phase2_optimize.ps1  ← Telemetry, services, visual tweaks, power plan
    └── phase3_cleanup.ps1   ← Disk cleanup, WU cache, DISM
```

The `.bat` launcher calls each `.ps1` with `-ExecutionPolicy Bypass` — **no manual policy changes needed**.

---

## Safety Notes

- All scripts use `try/catch` blocks — a single failure will not abort the phase.
- Phase 2 disables `WSearch` (Windows Search indexing) and `SysMain` (Superfetch). Re-enable manually if you experience issues: `Set-Service WSearch -StartupType Automatic`.
- Phase 3 stops Windows Update services temporarily to clear the cache, then restarts them.
- A system restore point before running is always a good idea.

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+ (built-in on all modern Windows versions)
- Administrator privileges (the launcher handles elevation automatically)

---

## License

MIT
