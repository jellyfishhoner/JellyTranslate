# JellyTranslate Signed Release

Goal: testers should download JellyTranslate, move it to Applications, open it, grant permissions, and start using it. No Terminal commands.

The current unsigned alpha zip is useful for private testing, but it is not a real tester-friendly installer. For a normal macOS install experience, JellyTranslate must be Developer ID signed and notarized.

## Decision

Use this release path for builds sent to non-technical testers:

1. Archive in Xcode.
2. Distribute with `Developer ID`.
3. Let Xcode upload the archive for Apple notarization.
4. Export the notarized app.
5. Package the exported app as a `.dmg` or `.zip`.
6. Verify the final artifact.
7. Upload it to GitHub Releases.
8. Point the website download button to that signed/notarized artifact.

Unsigned `.zip` builds are only for internal development and very technical testers.

## Why This Is Required

When a tester downloads an unsigned or non-notarized app, macOS Gatekeeper can block it with messages like:

- `JellyTranslate is damaged and can't be opened`
- `Apple cannot check it for malicious software`
- `developer cannot be verified`

This is expected macOS behavior. A `.dmg` alone does not fix it. The app inside the `.dmg` still needs Developer ID signing and notarization.

## One-Time Apple Setup

Required:

- Apple Developer Program membership.
- A `Developer ID Application` certificate installed in Keychain.
- The paid Apple Developer team selected in Xcode.

Steps:

1. Open `Xcode > Settings > Accounts`.
2. Add the Apple ID that owns the developer membership.
3. Select the team.
4. Click `Manage Certificates`.
5. Create or download a `Developer ID Application` certificate.

## Xcode Project Setup

The project already has:

- Bundle ID: `app.jellytranslate.JellyTranslate`
- Hardened Runtime: enabled
- App icon asset: `AppIcon`
- Automatic signing: enabled

Still needed before a public tester release:

1. Open `JellyTranslate.xcodeproj`.
2. Select the `JellyTranslate` target.
3. Open `Signing & Capabilities`.
4. Select the paid Apple Developer team.
5. Confirm there are no signing errors.

Do not commit personal Apple account data or local signing files.

## Build And Notarize With Xcode

Recommended first path:

1. Select scheme `JellyTranslate`.
2. Select destination `Any Mac` if available, otherwise `My Mac`.
3. Choose `Product > Archive`.
4. In Organizer, select the archive.
5. Click `Distribute App`.
6. Choose `Developer ID`.
7. Choose `Upload` so Xcode sends the app to Apple for notarization.
8. Wait for notarization to finish.
9. Export the notarized app.

After export:

1. Put `JellyTranslate.app` in a clean folder.
2. Create `JellyTranslate-VERSION-mac.zip` or a `.dmg`.
3. Upload the final artifact to GitHub Releases.
4. Update `site/index.html` so `Download on Mac` points to the new file.

## Verify Before Publishing

Run the helper script:

```sh
scripts/verify-release-app.sh /path/to/JellyTranslate.app
```

Expected:

- Code signature verification succeeds.
- Gatekeeper assessment says the app is accepted.

Manual commands:

```sh
codesign --verify --deep --strict --verbose=2 /path/to/JellyTranslate.app
spctl --assess --type execute --verbose /path/to/JellyTranslate.app
```

If either command fails, do not send the build to testers as the main download.

## Tester-Friendly Release Criteria

Before changing the website download link, confirm:

- The app opens on your Mac after downloading it from GitHub Releases.
- No `xattr` command is needed.
- The menu bar icon appears.
- Quick Start opens.
- Accessibility permission request is understandable.
- TextEdit test works with the default popup shortcut.
- Target language picker works in the popup.
- Replace shortcut works where macOS allows paste.

## Current Limitation

Until the project is signed with a paid Apple Developer ID and notarized by Apple, we can only improve documentation for private alpha testing. We cannot fully remove Gatekeeper warnings for arbitrary testers with an unsigned build.
