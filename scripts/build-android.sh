#!/usr/bin/env bash
set -euo pipefail
npm install
if [ ! -d android ]; then npx cap add android; fi
npx cap sync android
cd android
./gradlew assembleDebug --no-daemon
printf '\nAPK: android/app/build/outputs/apk/debug/app-debug.apk\n'
