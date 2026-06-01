# JellyTranslate MVP Testing

This document is for daily-use stability testing of the current MVP.

## Run the app

1. Open `JellyTranslate.xcodeproj` in Xcode.
2. Select the `JellyTranslate` scheme.
3. Run the app.
4. The app appears as a menu bar utility named `Jelly`.
5. Default popup shortcut: `command+z`; default replace shortcut: `command+s`.

## Enable permissions

Open System Settings > Privacy & Security and enable:

- Accessibility: required for reading selected text through macOS Accessibility APIs.
- Input Monitoring: may be required for simulated `Cmd+C` / `Cmd+V` fallback and Escape/outside-click global handling.
- Screen Recording: not used in the MVP; reserved for future OCR.

The popup can open Accessibility or Input Monitoring settings when a related failure is detected.

## Quick Start onboarding

### First launch

1. Reset onboarding if needed:
   `defaults delete app.jellytranslate.JellyTranslate JellyTranslate.onboardingCompleted`
2. Run JellyTranslate.

Expected:

- A small `JellyTranslate Quick Start` window opens on first launch.
- It explains the core flow: select text, press the shortcut, see translation.
- It does not block the app if Accessibility is not granted.

### Permission status

1. Open Quick Start.
2. Go to the Permissions step.
3. Toggle JellyTranslate in System Settings > Privacy & Security > Accessibility.
4. Reopen Quick Start if needed.

Expected:

- Status shows `Granted` or `Not granted`.
- `Open Privacy & Security Settings` opens the Accessibility privacy pane.

### Provider setup from onboarding

1. Open Quick Start.
2. Go to Translation Provider.
3. Choose `Mock Provider`.
4. Finish, then translate selected text.
5. Reopen Quick Start from the menu bar and choose `OpenAI Provider`.
6. Enter an OpenAI key and click `Save Key`.

Expected:

- Provider choice updates the same Settings used by the app.
- OpenAI key is saved to Keychain.
- Custom Provider is shown as a simple secondary choice; detailed setup stays in Settings > Advanced.

### Reopen Quick Start

1. Click the menu bar item.
2. Choose `Quick Start`.

Expected:

- Quick Start opens even after onboarding was completed.

### Finish onboarding

1. Complete the final `Try it` step.
2. Click `Finish`.
3. Quit and relaunch JellyTranslate.

Expected:

- Quick Start does not auto-open again.
- The menu item can still reopen it.

## Configure providers

## Interface language

1. Open `Settings`.
2. Change `App Language` to `English`.
3. Open the menu bar menu, popup, Quick Start, Settings, and History.
4. Change `App Language` to `Русский`.
5. Repeat the same UI check.

Expected:

- Menu items, popup actions, Quick Start, Settings, and History switch between English and Russian.
- `App Language` changes only JellyTranslate's interface.
- `Target language` remains separate and does not change when App Language changes.
- A user can use Russian UI while translating to English, Serbian, or any other target language.

### Mock Provider

1. Open JellyTranslate Settings from the menu bar.
2. Select `Mock`.
3. Leave API keys empty.
4. Select any text and press `command+z`.

Expected:

- Translation returns immediately with a local mock prefix.
- No network request is made.
- No API key is required.

### MyMemory Provider

Use this when you want real translation during development without OpenAI billing or an API key.

1. Open JellyTranslate Settings from the menu bar.
2. Select `MyMemory`.
3. Leave API key fields empty.
4. Select a short text snippet and press `command+z`.

Expected:

- Translation uses the free MyMemory API.
- No API key or card is required.
- The popup badge shows `MyMemory · Auto → RU`.
- This is suitable for MVP testing, not production quality.

Known limits:

- Free requests are limited; keep snippets short.
- Auto source detection is lightweight in JellyTranslate for this provider.
- Quality can vary because this is a public/free provider.

### OpenAI Provider

1. Open JellyTranslate Settings from the menu bar.
2. Select `OpenAI`.
3. Paste an OpenAI API key into the API key field.
4. Click `Save Key`.
5. Choose a target language.
6. Select text in another app and press `command+z`.

Expected:

- The key is stored in macOS Keychain.
- The selected text is sent to OpenAI only after the shortcut is triggered.
- The popup badge shows provider and language pair, for example `OpenAI · Auto → RU`.
- Missing or invalid API keys show friendly provider errors.

### LibreTranslate Provider

Use this path when you want real translation without OpenAI billing.

1. Open JellyTranslate Settings from the menu bar.
2. Select `LibreTranslate`.
3. Leave the API key empty for a self-hosted instance that does not require one, or paste a LibreTranslate key and click `Save Key`.
4. Open `Advanced`.
5. Set `LibreTranslate Provider` > `Base URL`.
   - Default: `https://libretranslate.com`
   - Self-hosted example: `http://localhost:5000` in DEBUG builds.
6. Choose a target language.
7. Select text and press `command+z`.

Expected:

- LibreTranslate API key, if provided, is stored in macOS Keychain.
- Base URL is stored in normal app settings because it is not a secret.
- The request uses LibreTranslate's `/translate` endpoint.
- The popup badge shows `LibreTranslate · Auto → RU`.
- API keys and selected text request bodies are not logged.

Known limits:

- Some public LibreTranslate instances require an API key, throttle heavily, or block automated requests.
- `http://` is allowed only in DEBUG builds for local/self-hosted testing; Release builds require `https://`.
- LibreTranslate language support depends on the chosen server.

### Custom OpenAI-Compatible API

1. Open JellyTranslate Settings from the menu bar.
2. Select `Custom`.
3. Paste the Custom Provider API key into the API key field.
4. Open `Advanced`.
5. Enter a base URL, for example `https://api.example.com`.
6. Keep the default path `/v1/chat/completions`, or set the provider-specific path.
7. Enter the model name required by the provider.
8. Click `Save Key`.
9. Select text and press `command+z`.

Expected:

- The Custom Provider key is stored in macOS Keychain.
- Base URL, path, and model are stored in normal app settings because they are not secrets.
- The popup badge shows `Custom · model-name · Auto → RU` when a model is configured.
- The request uses a chat/completions-compatible body with system and user messages.
- API keys, Authorization headers, and selected text request bodies are not logged.

### Invalid Custom Base URL

1. Select `Custom`.
2. Open `Advanced` and clear the Base URL field.
3. Try values such as `not-a-url` or `http://example.com` in a Release build.
4. Trigger translation.

Expected:

- Empty Base URL shows a clear validation message in Settings.
- Invalid URL shows a provider error.
- `https://` is required outside DEBUG builds.
- `http://` is allowed only in DEBUG builds for local testing.

### DeepL Provider

DeepL is still a placeholder. It is visible in Settings to keep the provider architecture ready, but translation should show a `Coming soon` style provider error.

## Manual test checklist

### Selected text capture

For each app, select short text, long text, and an empty selection, then press `command+z`.

- Safari editable fields.
- Safari non-editable webpage text.
- Chrome editable fields.
- Chrome non-editable webpage text.
- Telegram message text and compose input.
- Notes body text.
- TextEdit plain text and rich text.
- Pages document text, if available.
- Preview/PDF selectable text, if available.
- Any native input field, such as search fields and text areas.

Expected:

- If Accessibility exposes selected text, JellyTranslate should translate without changing clipboard.
- If Accessibility does not expose selected text, copy fallback should translate and then restore previous clipboard contents.
- If neither path works, a friendly empty/error state should appear.

### Clipboard fallback

1. Copy a known value to the clipboard.
2. Select text in an app where Accessibility is unreliable, such as webpage text.
3. Trigger JellyTranslate.
4. Paste into a temporary text field.

Expected:

- The original clipboard value should still be present.
- Selected source text should not be left in the clipboard.
- Empty selection should not translate stale clipboard content.

### Popup behavior

- Trigger near every screen edge and corner.
- Trigger on multiple displays if available.
- Trigger using both configured shortcuts.
- Press Escape.
- Click outside the popup.
- Trigger again while a popup is already visible.
- Use Copy, Replace, Speak, and History.

Expected:

- Popup stays on-screen and near the cursor.
- Popup does not activate as a normal app window.
- Escape closes it when event monitoring is permitted.
- Outside click closes it when event monitoring is permitted.
- Repeated shortcut updates and repositions the existing popup.

### Shortcut settings

1. Open Settings > Hotkeys.
2. Click `Show translation` and press a shortcut, such as `command + Z`.
3. Click `Translate and replace` and press another shortcut, such as `command + S`.
4. Select text and test the popup shortcut.
5. Select text again and test the replace shortcut in TextEdit or Notes.
6. Clear the replace shortcut and test the popup shortcut again.

Expected:

- Hotkey fields record the combination the user presses.
- The popup shortcut opens JellyTranslate's floating translation popup.
- The replace shortcut translates and pastes the translation over the selected text where the target app allows paste.
- Clearing one slot does not disable the other slot.
- Unsupported or conflicting system shortcuts may fail to register; choose another combination if one does not respond.

### Minimal history

1. Open Settings and turn on `Save history`.
2. Translate two or three pieces of text.
3. Open History from the popup or menu bar.
4. Search for a word from the original or translated text.
5. Click `Copy` on one item.
6. Click `Delete` on one item.
7. Click `Clear All`.

Expected:

- History stays lightweight: recent translations list, search, copy translated text, delete, clear all.
- It should not feel more important than the translation popup.
- API keys are never stored in history.
- If `Save history` is off, successful translations are not persisted.

### Corrupted history file

If practical:

1. Quit JellyTranslate.
2. Replace `~/Library/Application Support/JellyTranslate/history.json` with invalid JSON.
3. Relaunch JellyTranslate and open History.

Expected:

- The app does not crash.
- History shows a warning and safe empty state.
- `Clear` or `Clear All` lets the user recover.

### Permissions

1. Remove JellyTranslate from Accessibility.
2. Try selected text in Safari/Chrome/Notes/TextEdit.
3. Use the popup's settings button.
4. Enable Accessibility and retry.

Expected:

- Missing Accessibility should produce a clear explanation when capture fails.
- The settings button should open the relevant Privacy & Security pane.
- After permission is enabled, capture should become more reliable.

### Error handling

- Select OpenAI with an empty API key.
- Select OpenAI with an invalid API key.
- Select Custom Provider with an empty API key.
- Select Custom Provider with an invalid Base URL.
- Select Custom Provider with an invalid API key.
- Disable network while using OpenAI.
- Select DeepL.
- Try apps that block copy or do not expose selected text.

Expected:

- Missing API key shows a provider setup error.
- Invalid API key shows an invalid-key error.
- OpenAI malformed responses should show a provider response error.
- Custom Provider unreachable/401/403/malformed response cases should show friendly provider errors.
- Provider timeout should appear after 12 seconds.
- Empty selected text should not use stale clipboard content.
- Unsupported app behavior should show a friendly message.

## Known limitations

- OpenAI Provider uses the Responses API directly via `URLSession`.
- Custom Provider targets common chat/completions-compatible APIs. Providers that require nonstandard parameters, custom auth headers, streaming-only responses, or different response shapes may not work yet.
- Custom Provider Base URL and model are not secrets and are stored in normal settings. Custom Provider API key is stored in Keychain.
- DeepL Provider is still a placeholder.
- Non-editable webpage/PDF text often relies on copy fallback because Accessibility does not always expose selection.
- Some apps block simulated copy or require Input Monitoring.
- Escape and outside-click close behavior can depend on macOS event monitoring permission.
- Multi-display positioning now uses the screen containing the cursor, but unusual display arrangements should still be tested manually.
- Clipboard restoration preserves pasteboard items when possible, but some apps place custom/private pasteboard types that may not round-trip perfectly.
- OCR is intentionally not implemented yet.
- History is intentionally minimal: no filters, tags, analytics, cloud sync, or database layer.

## Next improvements

- Implement real DeepL provider calls.
- Add advanced Custom Provider options only if real providers require them.
- Add a small permission onboarding screen.
- Add automated UI tests around popup states.
- Add optional shortcut recorder UI instead of text-based shortcut entry.
