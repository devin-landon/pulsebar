#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP="$ROOT/PulseBar.app"
CONFIG="${CONFIG:-release}"
UNIVERSAL="${UNIVERSAL:-0}"

# Escape hatches for CI containers and restricted sandboxes where SwiftPM's
# own sandbox or the user module cache is unavailable.
if [ "${PULSEBAR_LOCAL_CACHES:-0}" = "1" ]; then
    mkdir -p "$ROOT/.tmp" "$ROOT/.cache/clang" "$ROOT/.cache/swiftpm"
    export TMPDIR="$ROOT/.tmp"
    export CLANG_MODULE_CACHE_PATH="$ROOT/.cache/clang"
    export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT/.cache/swiftpm"
fi

SWIFT_EXTRA=""
if [ "${PULSEBAR_DISABLE_SANDBOX:-0}" = "1" ]; then
    SWIFT_EXTRA="--disable-sandbox"
fi

build_binary() {
    local arch="$1"
    if [ -n "$arch" ]; then
        local scratch="$ROOT/.build/universal-$arch"
        swift build -c "$CONFIG" --arch "$arch" --scratch-path "$scratch" $SWIFT_EXTRA
        swift build -c "$CONFIG" --arch "$arch" --scratch-path "$scratch" --show-bin-path $SWIFT_EXTRA
    else
        swift build -c "$CONFIG" $SWIFT_EXTRA
        swift build -c "$CONFIG" --show-bin-path $SWIFT_EXTRA
    fi
}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [ "$UNIVERSAL" = "1" ]; then
    ARM_DIR="$(build_binary arm64 | tail -n 1)"
    X86_DIR="$(build_binary x86_64 | tail -n 1)"
    lipo -create "$ARM_DIR/PulseBar" "$X86_DIR/PulseBar" -output "$APP/Contents/MacOS/PulseBar"
else
    BIN_DIR="$(build_binary "" | tail -n 1)"
    cp "$BIN_DIR/PulseBar" "$APP/Contents/MacOS/PulseBar"
fi

cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
    cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi
printf 'APPL????' > "$APP/Contents/PkgInfo"

xattr -cr "$APP"
codesign --force --deep --sign - "$APP" >/dev/null
codesign --verify --deep --strict "$APP"

printf 'Built %s\n' "$APP"
printf 'Run with: open "%s"\n' "$APP"
