# JellyTranslate Tester Guide

Thank you for testing JellyTranslate.

JellyTranslate is a small macOS menu bar utility:

1. Select text anywhere on your Mac.
2. Press the shortcut.
3. Get an instant translation.

This is an early test build, so a few macOS permission steps are expected.

## Install

1. Download the latest `JellyTranslate` build from the GitHub Release.
2. If the file is a `.zip`, unzip it.
3. Move `JellyTranslate.app` to `Applications`.
4. Open `JellyTranslate.app`.

If macOS says the app cannot be opened because the developer cannot be verified:

1. Open `System Settings`.
2. Go to `Privacy & Security`.
3. Scroll down and click `Open Anyway` for JellyTranslate.
4. Confirm that you want to open it.

This warning appears on early unsigned or non-notarized test builds.

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
4. Press `Command+Z`.

Expected:

- A JellyTranslate popup appears.
- The popup shows the original text and a translation.
- You can change the target language in the popup.
- `Copy` copies the translation.
- `Replace` replaces selected text where macOS allows it.

Direct replacement shortcut:

1. Select text again.
2. Press `Command+S`.
3. JellyTranslate should translate and replace the selection directly.

Note: these default shortcuts are for early testing and can be changed in Settings.

## Provider

For the first test, use `MyMemory`.

- It does not require an API key.
- It is free for MVP testing.
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
- Share anonymous usage analytics

Anonymous analytics are off by default. If you enable them, JellyTranslate sends only technical events such as launch, translation success/failure, provider, target language, app version, and broad text-length bucket. It does not send selected text, translations, clipboard content, API keys, or window titles.

## What To Report

Please send:

- macOS version.
- Mac model if known.
- Which app you tested in: TextEdit, Notes, Safari, Chrome, Telegram, etc.
- Whether Accessibility permission was enabled.
- Whether Input Monitoring permission was enabled.
- Screenshot of any JellyTranslate error.
- Short description of what you expected and what happened.

Please do not send:

- API keys.
- Private text you translated.
- Authorization headers or request bodies.

## Known Issues

- Unsigned test builds can trigger macOS security warnings.
- Some apps block selected-text capture.
- Clipboard fallback can fail in some apps.
- Direct replacement can fail if the active app changes or blocks paste.
- DeepL, OCR, subscriptions, billing, and cloud sync are not implemented.
