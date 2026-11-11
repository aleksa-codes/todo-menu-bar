#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:---build}"
case "$MODE" in --build|--restart|--package) ;; *) echo "Usage: build.sh [--build|--restart|--package]" >&2; exit 1 ;; esac
APP="$PWD/dist/Todo Menu Bar.app"
if [ "$MODE" = "--package" ]; then
    mkdir -p .build
    STAGING="$(mktemp -d "$PWD/.build/package.XXXXXX")"
    trap 'rm -rf "$STAGING"' EXIT
    APP="$STAGING/Todo Menu Bar.app"
elif [ "$MODE" = "--build" ]; then
    swift scripts/app-control.swift check "$APP"
fi
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
if [ "$MODE" = "--restart" ]; then swift scripts/app-control.swift stop "$APP"; fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/TodoMenuBar" "$APP/Contents/MacOS/TodoMenuBar"
cp Info.plist "$APP/Contents/Info.plist"
cp Sources/TodoMenuBar/Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - --identifier codes.aleksa.todo-menu-bar "$APP"
codesign --verify --strict "$APP"
# Let IconServices notice icon changes inside an existing app bundle.
touch "$APP"
echo "Built: $APP"
if [ "$MODE" = "--restart" ]; then open "$APP"; fi
if [ "$MODE" = "--package" ]; then
    mkdir -p dist
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$PWD/dist/Todo-Menu-Bar-macOS.zip"
    mkdir -p "$STAGING/dmg"
    ditto "$APP" "$STAGING/dmg/Todo Menu Bar.app"
    ln -s /Applications "$STAGING/dmg/Applications"
    hdiutil create -volname "Todo Menu Bar" -srcfolder "$STAGING/dmg" -ov -format UDZO "$PWD/dist/Todo-Menu-Bar-macOS.dmg"
    echo "Packaged: $PWD/dist/Todo-Menu-Bar-macOS.dmg"
    echo "Packaged: $PWD/dist/Todo-Menu-Bar-macOS.zip"
fi
