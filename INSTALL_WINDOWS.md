# Install Flutter on Windows (for Krmaazha Team Hub)

Your error means **Flutter is not installed** or **not on PATH**. Follow these steps once.

## 1. Download Flutter SDK

1. Open: https://docs.flutter.dev/get-started/install/windows
2. Download the **stable** Windows zip (~1 GB).

Do **not** install under `C:\Program Files`. Use your user folder, for example:

`C:\Users\MARIUM\flutter`

After extracting, you should have:

`C:\Users\MARIUM\flutter\bin\flutter.bat`

## 2. Add Flutter to PATH (permanent)

If Flutter is already on your PC (for example):

`C:\Program Files\flutter_windows_3.44.0-stable\flutter\bin`

add that folder to PATH:

1. Press **Win**, type **environment variables**, open **Edit environment variables for your account**.
2. Under **User variables**, select **Path** → **Edit** → **New**.
3. Paste your `flutter\bin` path (the folder that contains `flutter.bat`).
4. Click **OK** on all dialogs.
5. **Close PowerShell completely** and open a **new** window.

Or run this once in PowerShell (replace the path if yours differs):

```powershell
$flutterBin = "C:\Program Files\flutter_windows_3.44.0-stable\flutter\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*flutter*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$flutterBin", "User")
}
```

Then **close and reopen** PowerShell.

Check:

```powershell
flutter --version
```

## 3. Install tools for Windows desktop

Krmaazha needs **Windows desktop** support:

```powershell
flutter doctor
```

Install what `flutter doctor` asks for. For **Windows** apps you typically need:

- **Visual Studio 2022** (Community is free)
- Workload: **Desktop development with C++**

Guide: https://docs.flutter.dev/platform-integration/windows/setup

Enable Windows target:

```powershell
flutter config --enable-windows-desktop
```

## 4. Run Krmaazha setup

```powershell
cd C:\Users\MARIUM\krmaazha_hub
.\setup.ps1
flutter run -d windows
```

## Quick test (PATH only in this window)

If you extracted Flutter but have not restarted the terminal yet:

```powershell
$env:PATH += ";C:\Users\MARIUM\flutter\bin"
flutter --version
```

Replace the path with your actual `flutter\bin` folder.

## Android (optional later)

For `flutter run -d android` you also need **Android Studio** and accept licenses:

```powershell
flutter doctor --android-licenses
```
