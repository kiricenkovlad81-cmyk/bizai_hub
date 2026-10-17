#!/usr/bin/env bash
# Generates platform folders (Android, iOS, Web, Windows, macOS, Linux) next to the app code
# and allows network access for the optional Claude API feature.
set -e
cd "$(dirname "$0")"

flutter create . --project-name bizai_hub --org kz.bizai --platforms=android,ios,web,windows,macos,linux

MANIFEST=android/app/src/main/AndroidManifest.xml
if [ -f "$MANIFEST" ] && ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi

for ENT in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
  if [ -f "$ENT" ] && ! grep -q "com.apple.security.network.client" "$ENT"; then
    perl -0pi -e 's#</dict>#\t<key>com.apple.security.network.client</key>\n\t<true/>\n</dict>#' "$ENT"
  fi
done

flutter pub get
echo ""
echo "Готово. Запуск: flutter run  (телефон)  |  flutter run -d chrome  (браузер)  |  flutter run -d macos / -d linux  (ПК)"
