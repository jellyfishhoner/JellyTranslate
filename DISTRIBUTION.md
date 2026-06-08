# JellyTranslate Distribution

This file describes the practical path for sharing JellyTranslate with early testers through GitHub.

## Recommended Path

Use GitHub in two layers:

1. GitHub repository for source code.
2. GitHub Releases for test builds, uploaded as `.zip` or later `.dmg`.

For the first small group of testers, a zipped `.app` is enough. For a wider audience, use a signed and notarized `.dmg`.

## Step 1. Prepare The Repository

Do not upload local Xcode build output or user state.

Keep:

- `JellyTranslate.xcodeproj`
- `JellyTranslate/`
- `README.md`
- `FIRST_RUN_TEST.md`
- `TESTING.md`
- `DEBUGGING.md`
- `README_FOR_TESTERS.md`
- `DISTRIBUTION.md`

Do not upload:

- `.derivedData/`
- `.build/`
- `xcuserdata/`
- `.DS_Store`
- API keys
- local archives
- generated `.zip` or `.dmg` release files

The `.gitignore` file is configured for this.

## Step 2. Create GitHub Repository

1. Open GitHub.
2. Create a new repository, for example `JellyTranslate`.
3. Keep it private while testing, or public if you are ready to show the source code.
4. Do not add another README from GitHub if the local README already exists.

## Step 3. Push Source Code

From the `JellyTranslate` project folder:

```sh
git init
git add .
git commit -m "Initial JellyTranslate MVP"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/JellyTranslate.git
git push -u origin main
```

If the parent folder is already a git repository, create the GitHub repository from that existing git root instead.

## Step 4. Build For Testers

In Xcode:

1. Open `JellyTranslate.xcodeproj`.
2. Select scheme `JellyTranslate`.
3. Select destination `My Mac`.
4. Choose `Product > Clean Build Folder`.
5. Choose `Product > Build`.
6. Choose `Product > Show Build Folder in Finder`.
7. Open `Products/Debug`.
8. Find `JellyTranslate.app`.

For the first unsigned alpha:

1. Right-click `JellyTranslate.app`.
2. Choose `Compress "JellyTranslate.app"`.
3. Rename the zip to something like:
   `JellyTranslate-0.1.0-alpha-mac.zip`

## Step 5. Create GitHub Release

1. Open the GitHub repository.
2. Go to `Releases`.
3. Click `Draft a new release`.
4. Tag: `v0.1.0-alpha`.
5. Title: `JellyTranslate 0.1.0 Alpha`.
6. Upload `JellyTranslate-0.1.0-alpha-mac.zip`.
7. Add release notes from the template below.
8. Publish release or keep it as draft until ready.

## Download And Usage Metrics

GitHub Releases show download counts for each uploaded `.zip` or `.dmg` asset. Use those counts to estimate installs during alpha testing.

For in-app usage, JellyTranslate includes optional anonymous analytics through TelemetryDeck Ingest API v2. Before making a build that should report usage:

1. Create a TelemetryDeck app.
2. Copy its App ID and namespace.
3. Paste them into `JellyTranslateTelemetryDeckAppID` and `JellyTranslateTelemetryDeckNamespace` in `JellyTranslate/Resources/Info.plist`.
4. Build and distribute a fresh app.

Users still need to enable `Share anonymous usage analytics` in JellyTranslate Settings. Do not enable analytics by default for private test builds.

## Release Notes Template

```md
# JellyTranslate 0.1.0 Alpha

Early macOS test build.

Core flow:

- Select text.
- Press shortcut.
- See translation popup.
- Optional direct replace.

Default shortcuts:

- Control+Option+T: show translation popup.
- Control+Option+R: translate and replace selected text.

Recommended provider:

- MyMemory, no API key required.

Before testing:

- Read README_FOR_TESTERS.md.
- Enable Accessibility permission.
- Enable Input Monitoring if copy/replace is unreliable.

Known limitations:

- This build may not be signed/notarized yet.
- macOS may show a security warning on first launch.
- Some apps block selected-text capture or paste replacement.
- MyMemory is free but limited.
```

## Step 6. Invite Testers

Send testers:

- GitHub Release link.
- `README_FOR_TESTERS.md`.
- A short request: test in TextEdit first, then in the apps they actually use.

Suggested message:

```text
Hey! I’m testing JellyTranslate, a small macOS menu bar translator.

Please download the latest build here:
PASTE_RELEASE_LINK

Start with TextEdit:
1. Open JellyTranslate.
2. Enable Accessibility permission if macOS asks.
3. Type and select “Hello world”.
4. Press Control+Option+T.
5. Try changing the target language in the popup.

Please send me your macOS version, what app you tested in, and screenshots of any errors.
Do not send private text or API keys.
```

## Better Later: Signed DMG

Before sharing more broadly, use an Apple Developer account and distribute a signed/notarized `.dmg`.

Benefits:

- Fewer scary macOS warnings.
- Cleaner install experience.
- More trust for non-technical users.

Future steps:

1. Set signing team in Xcode.
2. Archive the app.
3. Export with Developer ID.
4. Notarize with Apple.
5. Package into `.dmg`.
6. Upload `.dmg` to GitHub Releases.
