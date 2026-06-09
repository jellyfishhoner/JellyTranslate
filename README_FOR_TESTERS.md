# JellyTranslate Tester Guide

Thank you for testing JellyTranslate.

JellyTranslate is a small macOS menu bar utility:

1. Select text anywhere on your Mac.
2. Press the shortcut.
3. Get an instant translation.

This is an early test version, so a few macOS permission steps are expected.

The current public test version is not signed yet. This means macOS may block the app after download even if the app itself is fine.

If you received a future signed and notarized release, you should not need Terminal commands. Download, unzip, move the app to Applications, and open it.

## Quick Start

1. Download the latest `JellyTranslate` file from the GitHub Release.
2. If the file is a `.zip`, unzip it.
3. Move `JellyTranslate.app` to `Applications`.
4. Open `JellyTranslate.app`.
5. If macOS blocks the app, follow the security warning step below.
6. Enable Accessibility permission when macOS asks.
7. Test in TextEdit first.

## If macOS Says The App Is Damaged

If macOS says `JellyTranslate is damaged and can't be opened`, macOS blocked the downloaded app because this test version is not signed yet. The download is not necessarily broken.

For testing:

1. Move `JellyTranslate.app` to `Applications`.
2. Open Terminal.
3. Run:

```sh
xattr -dr com.apple.quarantine /Applications/JellyTranslate.app
open /Applications/JellyTranslate.app
```

This warning appears on test versions that are not signed and notarized yet. A future signed version should not need this step.

## If macOS Says Developer Cannot Be Verified

If macOS says the app cannot be opened because the developer cannot be verified:

1. Open `System Settings`.
2. Go to `Privacy & Security`.
3. Scroll down and click `Open Anyway` for JellyTranslate.
4. Confirm that you want to open it.

## Permissions

JellyTranslate may need:

- Accessibility: to read selected text and replace text when possible.
- Input Monitoring: to use the clipboard fallback and simulated paste more reliably.

To enable permissions:

1. Open `System Settings > Privacy & Security > Accessibility`.
2. Enable `JellyTranslate`.
3. Open `System Settings > Privacy & Security > Input Monitoring`.
4. Enable `JellyTranslate` if it appears there.
5. Quit and reopen JellyTranslate after changing permissions.

## First Test

Use TextEdit first.

1. Open TextEdit.
2. Type: `Hello world`.
3. Select the text.
4. Press `Control+Option+T`.

Expected:

- A JellyTranslate popup appears.
- The popup shows the original text and a translation.
- You can change the target language in the popup.
- `Copy` copies the translation.
- `Replace` replaces selected text where macOS allows it.

Direct replacement shortcut:

1. Select text again.
2. Press `Control+Option+R`.
3. JellyTranslate should translate and replace the selection directly.

Note: these default shortcuts are for early testing and can be changed in Settings.

## Best Apps To Test First

Start with:

- TextEdit
- Notes
- Safari
- Chrome

Then try the apps you actually use, such as Telegram, Discord, Notion, Slack, or browser pages.

Some apps do not expose selected text to macOS Accessibility or block simulated paste. If JellyTranslate works in TextEdit but not in a specific app, please report the app name.

## Provider

For the first test, use `MyMemory`.

- It does not require an API key.
- It is free for first tests.
- It may have daily limits and variable translation quality.

OpenAI and Custom Provider are optional for testers who already have their own API keys.

## Settings

Open JellyTranslate from the menu bar icon, then choose `Settings`.

Useful settings:

- Provider
- Target language
- App language
- Show translation shortcut
- Translate and replace shortcut
- Save history

Some versions may include an optional anonymous analytics toggle. It is off by default and sends only technical events such as launch, translation success/failure, provider, target language, app version, and broad text-length bucket. It does not send selected text, translations, clipboard content, API keys, or window titles.

## What To Report

Please send:

- macOS version.
- Mac model if known.
- Which app you tested in: TextEdit, Notes, Safari, Chrome, Telegram, etc.
- Whether Accessibility permission was enabled.
- Whether Input Monitoring permission was enabled.
- Screenshot of any JellyTranslate error.
- Whether the macOS damaged-app warning appeared.
- Whether the first TextEdit test worked.
- Short description of what you expected and what happened.

Please do not send:

- API keys.
- Private text you translated.
- Authorization headers or request bodies.

## Known Issues

- Test versions that are not signed yet can trigger macOS security warnings.
- Some apps block selected-text capture.
- Clipboard fallback can fail in some apps.
- Direct replacement can fail if the active app changes or blocks paste.
- DeepL, OCR, subscriptions, billing, and cloud sync are not implemented.

## Short Message For Testers

You can send this message with the download link:

```text
Hey! Please test JellyTranslate for macOS.

Download:
https://github.com/jellyfishhoner/JellyTranslate/releases/latest

Important: this test version is not signed yet. If macOS says the app is damaged, move JellyTranslate.app to Applications and run this once in Terminal:

xattr -dr com.apple.quarantine /Applications/JellyTranslate.app

Then open JellyTranslate, enable Accessibility permission if asked, and test in TextEdit first:
1. Type Hello world.
2. Select it.
3. Press Control+Option+T.

Please send your macOS version, whether the popup appeared, and screenshots of any error.
```
