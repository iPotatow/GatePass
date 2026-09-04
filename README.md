# GatePass

**Make trusted local Mac apps runnable, then tune macOS preferences with an explicit, reversible workflow.**

[简体中文](README.zh-CN.md)

[![Build macOS app](https://github.com/iPotatow/GatePass/actions/workflows/build.yml/badge.svg)](https://github.com/iPotatow/GatePass/actions/workflows/build.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

GatePass is a native SwiftUI utility for advanced Mac users who want a clear, local workflow for two jobs that are usually handled by scattered shell commands: removing the download quarantine attribute from apps they already trust, and reviewing a curated set of macOS preference keys before applying changes.

## What GatePass does

| Workspace | Use it for |
| --- | --- |
| **App Access** | Find recently installed apps, remove `com.apple.quarantine` from trusted `.app` bundles, and see the read-only Gatekeeper assessment status. |
| **System Preferences** | Review 60 curated macOS preferences, stage changes, verify every write, and restore the values GatePass changed. |

### App Access

- Scans `/Applications` and the current user's `Applications` folder for apps installed during the last seven days.
- Shows each app's icon, name, and installation date. Drag an app to the drop area or choose one or more `.app` bundles with the file picker.
- Removes only the `com.apple.quarantine` attribute. Processing one app can optionally launch it when the operation finishes.
- Refreshes the list when the app becomes active and supports manual refresh.
- Reports whether Gatekeeper assessment is enabled without changing the system's global security policy.

![GatePass App Access workspace](assets/gatepass-app-access.png)

### System Preferences

- Reads a typed, curated catalog covering Finder, Dock, Desktop, screenshots, keyboard, text input, mouse, storage, Messages, Music, Terminal, and the menu bar.
- Filters preferences by system component or by the items currently waiting to be applied.
- Keeps every toggle in a pending draft. Nothing is written until you choose **Apply**.
- Uses `/usr/bin/defaults` with type-aware reads and writes, then reads each value back to verify the result.
- Refuses to overwrite a value that changed after the scan, and marks unsupported or access-restricted settings instead of guessing.
- Saves original values in a local recovery record, offers **Restore previous changes**, and keeps the latest 200 operation results in History.
- Identifies related processes that may need to relaunch after a verified change. Preferences with uncertain behavior are kept out of automatic recommendations.

![GatePass System Preferences workspace](assets/gatepass-system-preferences.png)

> [!WARNING]
> GatePass can reduce protections or change system behavior. Only process apps whose origin and integrity you have independently verified. Removing quarantine does **not** make an app safe, and changing a macOS preference does not replace a security review. Review every pending system change before applying it.

## Get GatePass

Download the latest ZIP or DMG from [GitHub Releases](https://github.com/iPotatow/GatePass/releases). The `0.2.0` release is the first release with the System Preferences workspace.

Every automated release contains:

- `GatePass.zip` for installation and in-app update flows.
- `GatePass-<version>.dmg` for first-time installation and manual updates.
- `SHA256SUMS` for integrity verification.

The release workflow builds on `main` when [`VERSION`](VERSION) changes, or when a matching version tag such as `v0.2.0` is pushed. Ordinary code-only pushes do not publish a release. The DMG also includes an optional quarantine helper; use it only after verifying the app's source.

## Quick start

1. Install `GatePass.app` in `/Applications` or `~/Applications`.
2. Open **App Access**, review the recent-app list, and process only an app you trust.
3. To change macOS preferences, open **System Preferences**, review the staged toggles, then select **Apply**.
4. Use **Restore previous changes** if you want to undo the values recorded by GatePass.

## Build locally

Requirements: macOS 13 or later and the full Xcode app. Command Line Tools alone cannot build this Xcode project.

```bash
git clone https://github.com/iPotatow/GatePass.git
cd GatePass
xcodebuild \
  -project GatePass.xcodeproj \
  -scheme "GatePass - Release" \
  -configuration Release \
  build
```

For a local debug build and launch, use `./script/build_and_run.sh`. To package a DMG manually, install `create-dmg` with Homebrew and run:

```bash
script/build_dmg.sh /path/to/GatePass.app <version> <release-directory>
```

## Project layout

| Path | Purpose |
| --- | --- |
| `GatePass/` | SwiftUI app, App Access flow, Gatekeeper status, and settings |
| `GatePass/Features/SystemPreferences/` | Catalog, typed defaults client, planner, executor, recovery, and history UI |
| `Tests/` | System Preferences regression suite and macOS defaults audit |
| `VERSION` | Single release version |
| `.github/workflows/` | Release packaging and cross-version preference checks |
| `script/` | Local build, run, DMG packaging, and DMG background helpers |

## Contributing

Focused issues and pull requests are welcome. Build the **GatePass - Release** scheme before submitting changes. Changes to the System Preferences catalog should include regression coverage and preserve the read-back and restoration guarantees.

## License

GatePass is licensed under the [Apache License 2.0](LICENSE).
