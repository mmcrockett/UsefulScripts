#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

WORK="$(mktemp -d)"
SET="${WORK}/AppIcon.iconset"
mkdir "${SET}"

swift make-icon.swift "${WORK}/base.png"

for size in 16 32 128 256 512; do
  sips -z "${size}" "${size}" "${WORK}/base.png" --out "${SET}/icon_${size}x${size}.png" >/dev/null
  sips -z "$((size * 2))" "$((size * 2))" "${WORK}/base.png" --out "${SET}/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "${SET}" -o ../Resources/AppIcon.icns
rm -rf "${WORK}"
echo "Wrote Resources/AppIcon.icns"
