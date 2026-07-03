# JellyTranslate Windows MVP

Windows is a separate proof of concept for now.

The first goal is not a polished public release. The first goal is to prove that the core qTranslate-style flow works reliably on Windows:

1. Select text in another app.
2. Press a global hotkey.
3. Capture selected text through clipboard fallback.
4. Translate with MyMemory.
5. Show a compact popup.
6. Optionally replace selected text.

## MVP Shortcuts

- `Ctrl+Alt+T`: show translation popup.
- `Ctrl+Alt+R`: translate and replace selected text.

## First Apps To Test

Start with simple apps:

- Notepad
- WordPad
- Browser text field

Then test real daily apps:

- Telegram
- Discord
- Notion
- Chrome/Safari-equivalent browser pages
- Microsoft Word

## Current Technical Choice

The Windows MVP uses C# + WinForms because it is practical for:

- tray icon;
- global hotkeys;
- clipboard fallback;
- popup windows;
- future installer/signing work.

## Current Limitations

- No installer yet.
- No app icon wired into the Windows executable yet.
- No settings UI yet.
- Target language is basic:
  - Cyrillic text goes to English.
  - Other text goes to Russian.
- Some apps can block simulated copy/paste.
- The UI is intentionally minimal and should be redesigned after the core flow is confirmed.

## Next Milestones

1. Build and run on Windows.
2. Confirm hotkeys work in Notepad.
3. Confirm selected text capture.
4. Confirm MyMemory translation.
5. Confirm direct replace.
6. Add settings for target language.
7. Add real icon and nicer popup styling.
8. Package as a test installer.
