# BASE 67

🚀 BASE 67

A Mars Settlement & Junior Astronaut Mission Training Game

🎮 [PLAY BASE 67 ONLINE](https://sajeed-dono.github.io/base67/)

Explore Mars, manage your settlement, lead your crew, and complete your astronaut training missions!

BASE 67 is an offline-first Flutter game prototype and junior astronaut mission
trainer. The Flutter project is in [`base67/`](base67/).

## Play online

Play the web build on GitHub Pages: [BASE 67](https://sajeed-dono.github.io/base67/).

## Android APKs

The repository includes the currently packaged APK:

- [`BASE 67.apk`](base67/BASE%2067.apk) — installable Android release package.

The release build script creates a freshly built copy at
`base67/dist/Base 67.apk` and writes its SHA-256 checksum to
`base67/dist/Base 67.apk.sha256`.

### Install and use the APK

1. Copy `BASE 67.apk` to an Android phone or tablet.
2. Open it with the Android file manager and allow installation from that
   source if Android asks for permission.
3. Install the app, then open **BASE 67** from the app launcher.

For an Android device connected through ADB, use:

```bash
adb install -r "base67/BASE 67.apk"
```

The `-r` option updates an existing installation while preserving its local
app data. Remove it if a clean installation is required.

## Build a new release APK

From the repository root, run the PowerShell build script:

```powershell
Set-Location base67
.\build_base67.ps1
```

The resulting APK is `base67/dist/Base 67.apk`. Flutter must be installed and
the Android SDK must be configured before building or installing the app.

## Development status

The foundation, prologue prototype, data layer, campaign model, and initial
architecture are in place. See [`base67/README.md`](base67/README.md) for
project commands and implementation details.
