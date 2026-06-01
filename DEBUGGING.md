# JellyTranslate Debugging

## Accessibility while running from Xcode

When JellyTranslate is launched from Xcode, macOS may treat the built app inside DerivedData as the permission target.

If Accessibility looks enabled but JellyTranslate still reports missing permission:

1. Stop JellyTranslate in Xcode.
2. Open `System Settings > Privacy & Security > Accessibility`.
3. Remove duplicate or old JellyTranslate entries.
4. Do not add the project folder.
5. In Xcode, choose `Product > Show Build Folder in Finder`.
6. Add the built `JellyTranslate.app` from the build products folder, or enable Xcode while running from Xcode.
7. Repeat for `Input Monitoring` if copy fallback or replace does not work.
8. Run JellyTranslate again with `Cmd+R`.

## DEBUG logs

In DEBUG builds, JellyTranslate logs permission diagnostics only. It does not log selected text, API keys, Authorization headers, or request bodies.

Useful log markers:

- `current bundleIdentifier`
- `current executable path`
- `accessibility_trusted_true`
- `accessibility_trusted_false`
- `accessibility_prompt_requested_manually`
- `accessibility_prompt_skipped`
- `capture_blocked_by_missing_permission`

## Text capture order

JellyTranslate captures selected text before showing the popup. This prevents the popup from stealing focus before clipboard fallback sends `Cmd+C`.
