# Krmaazha Team Hub

Local-first team management for Android and Windows desktop.

## Features

- Team head, co-lead, and member roles with permissions
- Tasks with assignees, priorities, checklists, and comments
- Meetings with calendar view and local reminders
- Activity feed and dashboard
- Export/import `.krmaazha` backup files
- Optional PIN / biometric app lock
- Optional LAN team session (same Wi-Fi)

## Setup

Requires [Flutter SDK](https://docs.flutter.dev/get-started/install) with Android and Windows desktop enabled.

```powershell
cd C:\Users\MARIUM\krmaazha_hub
.\setup.ps1
```

Use `.\setup.ps1` (dot-backslash), not `run setup.ps1`.

If scripts are blocked:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
.\setup.ps1
```

Or manually:

```bash
flutter create . --org com.krmaazha --project-name krmaazha_hub --platforms=android,windows
flutter pub get
flutter run -d windows
# or
flutter run -d android
```

## Build

```bash
flutter build apk
flutter build windows
```
