# JellyTranslate

JellyTranslate is a native macOS menu bar app for instant AI translation anywhere on Mac.

Core flow:

1. Select text anywhere on Mac.
2. Press a shortcut.
3. See the translation in a compact floating popup, or replace the selected text directly.

JellyTranslate is currently an early MVP for local and private testing.

## Features

- SwiftUI + AppKit menu bar app.
- Configurable global shortcuts.
- Default shortcuts for local testing:
  - `Command+Z`: show translation popup.
  - `Command+S`: translate and replace selected text.
- Reads selected text with Accessibility API when possible.
- Falls back to simulated `Cmd+C`, reads clipboard, then restores prior clipboard content.
- Floating always-on-top translation popup near cursor.
- Translation provider picker with MyMemory as the free default for MVP testing.
- Provider abstraction with MyMemory, Mock, real OpenAI support, LibreTranslate, Custom OpenAI-compatible API support, and DeepL placeholder.
- Copy translation, replace selected text, speak original, speak translation.
- Local JSON history in Application Support.
- Settings for provider, target language, app language, secure API key storage, custom provider base URL/model/path, shortcuts, behavior, and privacy.
- TODO OCR module reserved for Vision framework.

## First Run

Open `JellyTranslate.xcodeproj` in Xcode and run the `JellyTranslate` scheme on `My Mac`.

For manual local testing, follow [FIRST_RUN_TEST.md](FIRST_RUN_TEST.md).

For sharing a test build with other people, follow [DISTRIBUTION.md](DISTRIBUTION.md) and include [README_FOR_TESTERS.md](README_FOR_TESTERS.md) with the release.

## Website

The Netlify-ready landing page lives in [site](site). Netlify uses [netlify.toml](netlify.toml) to publish that folder.

## Permissions

For real use, grant these in System Settings > Privacy & Security:

- Accessibility: reading selected text from other apps.
- Input Monitoring: simulated copy/paste fallback.
- Screen Recording: not used in MVP, reserved for future OCR.

## Current Limitations

- MyMemory is useful for free testing but has limits and variable quality.
- Unsigned or non-notarized builds may show macOS security warnings.
- Some apps do not expose selected text through Accessibility.
- Direct replacement depends on whether the current app accepts simulated paste.
- OCR, billing, subscriptions, and cloud sync are intentionally out of scope.
