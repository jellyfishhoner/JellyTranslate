# JellyTranslate Release Checklist

Use this checklist before publishing a new build or updating the public download link.

## 1. Choose The Version

For alpha builds, keep the version in this shape:

```text
App version: 0.1.0
Git tag: v0.1.0-alpha
Release asset: JellyTranslate-0.1.0-alpha-mac.zip
Site label: 0.1.0 alpha
```

When the app version changes, update:

- `CFBundleShortVersionString` in `JellyTranslate/Resources/Info.plist`
- `releaseVersion` in `site/index.html`
- the download URL in `site/index.html`
- the download URL note in `site/README.md`

## 2. Check The Release State

Run this before building the public ZIP:

```sh
scripts/check-release-state.sh
```

It verifies that the app version, site version label, GitHub release tag, and ZIP filename agree with each other.

## 3. Build And Package

For the current unsigned alpha flow:

```sh
xcodebuild -project JellyTranslate.xcodeproj -scheme JellyTranslate -configuration Debug -destination 'platform=macOS' -derivedDataPath /private/tmp/JellyTranslateReleaseBuild CODE_SIGNING_ALLOWED=NO clean build
scripts/package-release-zip.sh /private/tmp/JellyTranslateReleaseBuild/Build/Products/Debug/JellyTranslate.app /private/tmp/JellyTranslate-0.1.0-alpha-mac.zip
```

For a signed public build, follow `RELEASE_SIGNING.md`.

## 4. Publish

1. Create or update the GitHub Release for the matching tag.
2. Upload the new ZIP asset.
3. Confirm the site download button uses that release asset.
4. Push the site changes so Netlify redeploys.

## 5. Quick Smoke Test

Download the ZIP from the public site, then verify:

- the file unzips into `JellyTranslate.app`
- the app opens after moving it to Applications
- the onboarding shows the current UI
- the menu can check for updates
- the site still scrolls to the tester guide after clicking Download
