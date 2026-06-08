# JellyTranslate First Local Test

Use this checklist for the first real run on your Mac.

## 1. Open in Xcode

1. Open Xcode.
2. Choose `File > Open...`.
3. Select:
   `JellyTranslate/JellyTranslate.xcodeproj`
4. Wait for Xcode to index the project.

## 2. Select scheme

1. In the top toolbar, open the scheme selector.
2. Select scheme: `JellyTranslate`.
3. Select destination: `My Mac`.

Expected:

- Product target is `JellyTranslate`.
- App product is `JellyTranslate.app`.

## 3. Build and run

1. Press `Cmd+B` to build.
2. If build succeeds, press `Cmd+R` to run.

Expected:

- The app does not show a Dock icon.
- A menu bar item named `Jelly` appears.
- On first launch, `JellyTranslate Quick Start` appears.

Note:

- In this Codex environment, full `xcodebuild` cannot run because the active developer directory is `/Library/Developer/CommandLineTools`, not a full Xcode install. Local Xcode build on your Mac is the source of truth for this step.

## 4. Enable permissions

1. In Quick Start, go to `Permissions`.
2. Click `Open Privacy & Security Settings`.
3. Enable JellyTranslate under:
   `System Settings > Privacy & Security > Accessibility`
4. If copy/paste fallback or Escape/outside-click behavior is unreliable, also enable:
   `System Settings > Privacy & Security > Input Monitoring`
5. If running from Xcode, you may also need to enable Accessibility and Input Monitoring for Xcode itself.
6. If there are duplicate JellyTranslate entries, remove old entries first. Do not add the project folder.
7. To add the exact built app, use Xcode `Product > Show Build Folder in Finder`, then add the built `JellyTranslate.app` from the build products folder.
8. macOS may grant permission to the `.app` inside Xcode DerivedData, not the project folder.
9. After changing permissions, stop the app in Xcode and run it again with `Cmd+R`.

Expected:

- Quick Start shows Accessibility as `Granted` after reopening it.
- The app still runs if permission is not granted, but some apps may need clipboard fallback.
- JellyTranslate should not repeatedly show the system Accessibility prompt once permission is granted.

## 5. Test Mock Provider first

1. Open menu bar item `Jelly`.
2. Choose `Quick Start` or `Settings`.
3. Select provider: `Mock`.
4. Select text in TextEdit, Notes, Safari, or Chrome.
5. Press:
   `control + option + T`

Expected:

- A floating popup appears near the cursor.
- Translation appears immediately with a mock prefix.
- No API key is required.
- `Copy` copies the translated text.
- `Replace` attempts to replace the selected text.

## 6. Test Settings

1. Open menu bar item `Jelly`.
2. Choose `Settings`.

Expected:

- Settings opens.
- You can change Provider, API key, Target language, App Language, shortcuts, and Save history.
- Advanced options are collapsed unless opened.

## 6b. Test shortcuts

1. Open `Settings`.
2. In `Hotkey`, click `Show translation`.
3. Press the shortcut you want for the popup, for example `control + option + T`.
4. Click `Translate and replace` if you want a direct replacement shortcut.
5. Press another shortcut, for example `control + option + R`.
6. Select text in TextEdit.
7. Press the popup shortcut and confirm the translation popup appears.
8. Select the text again and press the replace shortcut.
9. Clear the replace shortcut if you do not want direct replacement.

Expected:

- The app records the shortcut when you press the key combination.
- The first shortcut opens the translation popup.
- The second shortcut translates and immediately replaces selected text where paste replacement is allowed.
- The replace shortcut is optional and can stay empty.
- Empty shortcut fields are ignored.

## 6a. Test English and Russian UI

1. Open `Settings`.
2. Set `App Language` to `English`.
3. Check menu bar menu, popup, Quick Start, Settings, and History.
4. Set `App Language` to `Русский`.
5. Check the same areas again.

Expected:

- JellyTranslate UI switches language.
- Target translation language does not change.
- Russian UI can still translate to English, Serbian, or any other target language.

## 7. Test OpenAI Provider

1. Open `Settings`.
2. Select provider: `OpenAI`.
3. Paste your OpenAI API key into the API key field.
4. Click `Save Key`.
5. Select a target language.
6. Select text in another app.
7. Press `control + option + T`.

Expected:

- API key is stored in macOS Keychain.
- The selected text is sent only when you press the shortcut.
- Popup badge shows `OpenAI · Auto → XX`.
- Missing or invalid key shows a friendly error.

## 8. Test MyMemory Provider

Use this first if you do not want to pay for OpenAI while JellyTranslate is still in development.

1. Open `Settings`.
2. Select provider: `MyMemory`.
3. Leave API key fields empty.
4. Select a short text snippet.
5. Press `control + option + T`.

Expected:

- No OpenAI key, billing, or card is needed.
- Popup badge shows `MyMemory · Auto → XX`.
- Translation is real, but quality and limits are only suitable for development.

## 9. Test LibreTranslate Provider

Use this if OpenAI billing/card setup is not available.

1. Open `Settings`.
2. Select provider: `LibreTranslate`.
3. Optional: paste a LibreTranslate API key and click `Save Key`.
4. Open `Advanced`.
5. In `LibreTranslate Provider`, set Base URL:
   - Default: `https://libretranslate.com`
   - Local/self-hosted DEBUG example: `http://localhost:5000`
6. Select target language.
7. Select text and press `control + option + T`.

Expected:

- No OpenAI key is needed.
- If a LibreTranslate key is entered, it is stored in Keychain.
- Popup badge shows `LibreTranslate · Auto → XX`.
- Some public LibreTranslate servers may require a key or have rate limits.

## 10. Test Custom Provider

1. Open `Settings`.
2. Select provider: `Custom`.
3. Paste the custom API key and click `Save Key`.
4. Open `Advanced`.
5. Enter:
   - Base URL, for example `https://api.example.com`
   - Path, usually `/v1/chat/completions`
   - Model, for example the provider's model name
6. Select text and press `control + option + T`.

Expected:

- Custom API key is stored in Keychain.
- Base URL/model/path are stored in local app settings.
- Popup badge shows `Custom · model-name · Auto → XX`.

## 11. Test History

1. In Settings, turn on `Save history`.
2. Translate a few short snippets.
3. Open menu bar item `Jelly`.
4. Choose `History`.

Expected:

- Recent translations appear.
- Search filters the list.
- `Copy` copies translated text.
- `Delete` removes one item.
- `Clear All` removes all history.

## 12. Reset onboarding for testing

Quit JellyTranslate, then run:

```sh
defaults delete app.jellytranslate.JellyTranslate JellyTranslate.onboardingCompleted
```

Run the app again. Quick Start should appear automatically.

## Known issues

- DeepL is still a placeholder.
- MyMemory is a free development provider with limits and variable translation quality.
- LibreTranslate depends on the chosen server; public instances may require an API key or throttle requests.
- Custom Provider supports common chat/completions-compatible APIs only.
- Some apps do not expose selected text through Accessibility; JellyTranslate falls back to simulated `Cmd+C`.
- Clipboard fallback tries to restore the previous clipboard, but some private pasteboard formats may not round-trip perfectly.
- Hotkey recording supports common letter, number, punctuation, and space shortcuts with modifiers.
- Direct replacement can fail if the active app changes before translation finishes or if the app blocks simulated paste.
- OCR, billing, subscriptions, and cloud sync are intentionally not implemented.

## If something fails

Collect:

- Screenshot of the Xcode error navigator.
- The first red build error text from Xcode.
- Screenshot of the `Jelly` menu bar menu.
- Screenshot of Quick Start permission status.
- macOS version and Xcode version.
- Which app you selected text in, for example TextEdit, Notes, Safari, or Chrome.
- Whether Accessibility is enabled for JellyTranslate.
- Whether Input Monitoring is enabled for JellyTranslate.

Avoid sharing:

- OpenAI or Custom Provider API keys.
- Full selected text if it contains private content.
- Authorization headers or request bodies.
