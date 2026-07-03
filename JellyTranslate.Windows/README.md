# JellyTranslate for Windows

Early Windows proof of concept for JellyTranslate.

Goal: a small qTranslate-style tray app for Windows:

1. Select text in any app.
2. Press `Ctrl+Alt+T`.
3. See a compact translation popup.
4. Press `Ctrl+Alt+R` to translate and replace selected text.

## Current MVP

- WinForms tray app.
- Global hotkeys:
  - `Ctrl+Alt+T`: show translation popup.
  - `Ctrl+Alt+R`: translate and replace selected text.
- Clipboard fallback for selected text capture.
- MyMemory translation provider.
- Basic target auto-choice: Cyrillic text translates to English; everything else translates to Russian.
- Floating always-on-top popup near the cursor.

## Requirements

- Windows 10 or newer.
- For the CI build: no .NET install should be needed.
- For running from source: .NET 8 SDK.

## Run

```powershell
dotnet run --project JellyTranslate.Windows
```

## Download Build

GitHub Actions builds two Windows packages and publishes them to the `v0.1.0-alpha` GitHub Release:

- `JellyTranslate-0.1.0-alpha-windows-x64.zip` for most Intel/AMD Windows PCs.
- `JellyTranslate-0.1.0-alpha-windows-arm64.zip` for Windows on ARM devices.

The website downloads the right package after email signup, then opens the setup guide.

The build is self-contained, but it is not signed and does not include an installer yet.

## Notes

This is intentionally separate from the macOS Swift app. The first Windows milestone is to validate the core workflow before adding settings, history, installer, signing, and a polished UI.

Some apps may block simulated copy/paste. Test first in Notepad, WordPad, browser text fields, and Telegram/Discord/Notion after that.
