#!/bin/bash
set -e

mkdir -p DotNet/libs/Android/arm64-v8a
mkdir -p DotNet/libs/iOS
mkdir -p DotNet/libs/macOS
mkdir -p DotNet/libs/Windows/x86_64
mkdir -p DotNet/libs/visionOS
mkdir -p DotNet/include

find artifacts/android-* -name "*.so" -exec cp {} DotNet/libs/Android/arm64-v8a/ \; || true
find artifacts/iOS-* -name "*.a" -exec cp {} DotNet/libs/iOS/ \; || true
find artifacts/desktop-windows-* -name "*.dll" -exec cp {} DotNet/libs/Windows/x86_64/ \; || true
find artifacts/desktop-macos-* -name "*.dylib" -exec cp -R {} DotNet/libs/macOS/ \; || true
find artifacts/visionOS-* -name "*.a" -exec cp {} DotNet/libs/visionOS/ \; || true

INCLUDE_DIR=$(find artifacts -type d -name "include" | head -n 1 || true)
if [ -n "$INCLUDE_DIR" ]; then cp -R "$INCLUDE_DIR"/* DotNet/include; fi