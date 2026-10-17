# Generates platform folders (Android, iOS, Web, Windows, macOS, Linux) next to the app code
# and allows network access on Android for the optional Claude API feature.
# Run:  powershell -ExecutionPolicy Bypass -File setup.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

flutter create . --project-name bizai_hub --org kz.bizai --platforms=android,ios,web,windows,macos,linux

$manifest = Join-Path $PSScriptRoot "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifest) {
  $content = [IO.File]::ReadAllText($manifest)
  if ($content -notmatch "android.permission.INTERNET") {
    $content = $content.Replace("<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`n    <application")
    [IO.File]::WriteAllText($manifest, $content)
  }
}

flutter pub get
Write-Host ""
Write-Host "Готово. Запуск: flutter run -d windows (ПК) | flutter run -d chrome (браузер) | flutter run (телефон)"
