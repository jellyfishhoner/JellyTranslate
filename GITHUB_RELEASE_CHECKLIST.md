# GitHub Release Checklist

Use this before giving JellyTranslate to testers.

## Before Build

- [ ] Xcode opens `JellyTranslate.xcodeproj`.
- [ ] Scheme is `JellyTranslate`.
- [ ] Destination is `My Mac`.
- [ ] Provider default is suitable for testing, usually `MyMemory`.
- [ ] No real API keys are stored in source files.
- [ ] `README_FOR_TESTERS.md` is up to date.

## Build

- [ ] `Product > Clean Build Folder`.
- [ ] `Product > Build`.
- [ ] App launches from Xcode.
- [ ] Menu bar icon appears.
- [ ] Quick Start opens.
- [ ] Settings opens.
- [ ] TextEdit test works with `Command+Z`.
- [ ] Direct replace test works where possible with `Command+S`.
- [ ] Popup target language picker works and remembers the last selected language.

## Package

- [ ] Use `Product > Show Build Folder in Finder`.
- [ ] Find `JellyTranslate.app` in `Products/Debug`.
- [ ] Compress `JellyTranslate.app`.
- [ ] Rename zip to `JellyTranslate-VERSION-alpha-mac.zip`.

## GitHub Release

- [ ] Create tag, for example `v0.1.0-alpha`.
- [ ] Upload zip.
- [ ] Paste release notes.
- [ ] Link `README_FOR_TESTERS.md`.
- [ ] Mark clearly as alpha/test build.

## Tester Feedback

Ask testers for:

- [ ] macOS version.
- [ ] Tested app names.
- [ ] Permission status.
- [ ] Screenshot of error popup if any.
- [ ] Whether copy worked.
- [ ] Whether replace worked.
- [ ] Whether target language picker behaved correctly.

