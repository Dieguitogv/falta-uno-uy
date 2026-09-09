#!/usr/bin/env bash
set -e
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no está instalado o no está en PATH."
  exit 1
fi
flutter create . --platforms android --org uy.faltauno --project-name falta_uno_uy
flutter pub get
flutter build apk --release
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
