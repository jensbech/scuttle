#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/scripts/make-assets"
OUT="$ROOT/Assets"
PREVIEW="${1:-}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/scuttle-assets.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

swiftc -O -o "$WORK/icon" "$SRC/icon.swift"
swiftc -O -o "$WORK/menubar" "$SRC/menubar.swift"

rm -rf "$OUT"
mkdir -p "$OUT"

if [ -n "$PREVIEW" ]; then
    mkdir -p "$PREVIEW"
    "$WORK/icon" "$WORK" "$PREVIEW"
    "$WORK/menubar" "$OUT" "$PREVIEW"
else
    "$WORK/icon" "$WORK"
    "$WORK/menubar" "$OUT"
fi

iconutil --convert icns --output "$OUT/AppIcon.icns" "$WORK/AppIcon.iconset"
cp "$WORK/AppIcon-1024.png" "$OUT/AppIcon-1024.png"

ls -l "$OUT"
