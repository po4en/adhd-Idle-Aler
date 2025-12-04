# adhd-Idle-Aler
Small Windows tool that plays a beep sound when user is idle for too long.
<img width="450" height="217" alt="image" src="https://github.com/user-attachments/assets/14b1b63c-b59c-4249-ab3d-87ab558ab704" />

## Features

- Configurable idle threshold (minutes / seconds).
- Optional repeat interval for additional alerts.
- Countdown to first / next alert.
- Simple WinForms GUI written in PowerShell.

## Usage

1. Download `IdleAlert.exe` or `IdleAlert.ps1`.
2. Run the tool.
3. Set:
   - **Idle threshold** – how long you can be idle before first alert.
   - **Repeat every** – how often to repeat the alert (0 = only once).
4. Click **Start** to begin monitoring, **Stop** to stop.

### Running .ps1 file

**Option 1 (easiest):** Right-click `IdleAlert.ps1` → "Run with PowerShell"

**Option 2:** Open PowerShell, navigate to folder and run:
```powershell
.\IdleAlert.ps1
```

If you get execution policy error, run once:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Support

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://buymeacoffee.com/po4en)
