#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

swift build -c release

APP=build/MikePlayer.app
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp Resources/AppIcon.icns "${APP}/Contents/Resources/AppIcon.icns"
cp "$(swift build -c release --show-bin-path)/MikePlayer" "${APP}/Contents/MacOS/MikePlayer"
cp Resources/Info.plist "${APP}/Contents/Info.plist"
codesign -s - --force "${APP}"

if [[ "${1:-}" == "--install" ]]; then
  mkdir -p "${HOME}/Applications"
  rm -rf "${HOME}/Applications/MikePlayer.app"
  cp -R "${APP}" "${HOME}/Applications/MikePlayer.app"
  echo "Installed ${HOME}/Applications/MikePlayer.app"
else
  echo "Built ${APP}"
fi
