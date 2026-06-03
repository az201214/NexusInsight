# Run once from PowerShell:
#   cd C:\Users\MARIUM\krmaazha_hub
#   .\setup.ps1

Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

function Find-FlutterBin {
  if (Get-Command flutter -ErrorAction SilentlyContinue) {
    return $null
  }

  $candidates = @(
    "C:\Program Files\flutter_windows_3.44.0-stable\flutter\bin",
    "$env:USERPROFILE\flutter\bin",
    "$env:LOCALAPPDATA\flutter\bin",
    "C:\src\flutter\bin",
    "C:\flutter\bin"
  )

  # Any flutter install under Program Files (e.g. flutter_windows_*-stable\flutter\bin)
  $programFiles = @(
    ${env:ProgramFiles},
    ${env:ProgramFiles(x86)}
  ) | Where-Object { $_ -and (Test-Path $_) }

  foreach ($root in $programFiles) {
    $matches = Get-ChildItem -Path $root -Directory -Filter "flutter_windows_*" -ErrorAction SilentlyContinue
    foreach ($dir in $matches) {
      $bin = Join-Path $dir.FullName "flutter\bin"
      if (Test-Path (Join-Path $bin "flutter.bat")) {
        $candidates += $bin
      }
    }
  }

  foreach ($bin in $candidates) {
    $flutterBat = Join-Path $bin "flutter.bat"
    if (Test-Path $flutterBat) {
      return $bin
    }
  }

  return $null
}

$flutterBin = Find-FlutterBin
if ($null -ne $flutterBin) {
  Write-Host "Flutter found at $flutterBin - adding to PATH for this session."
  if ($env:PATH -notlike "*$flutterBin*") {
    $env:PATH = $flutterBin + ";" + $env:PATH
  }
}

$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterCmd) {
  Write-Host ""
  Write-Host "Flutter is not installed or not on PATH." -ForegroundColor Yellow
  Write-Host "Add this folder to your User PATH, then reopen PowerShell:"
  Write-Host "  C:\Program Files\flutter_windows_3.44.0-stable\flutter\bin"
  Write-Host ""
  Write-Host "Or run once in this window:"
  Write-Host '  $env:PATH = "C:\Program Files\flutter_windows_3.44.0-stable\flutter\bin;" + $env:PATH'
  Write-Host ""
  Write-Host "See INSTALL_WINDOWS.md for details."
  Write-Host ""
  exit 1
}

flutter create . --org com.krmaazha --project-name krmaazha_hub --platforms=android,windows
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Done. Run: flutter run -d windows"
