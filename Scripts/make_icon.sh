#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICONSET="$ROOT/.build/AppIcon.iconset"

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

swift "$ROOT/Scripts/GenerateIcon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$ROOT/Resources/AppIcon.icns"
rm -rf "$ICONSET"

printf 'Wrote %s\n' "$ROOT/Resources/AppIcon.icns"
