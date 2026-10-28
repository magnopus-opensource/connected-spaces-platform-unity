#!/bin/bash
set -e # Exit immediately if a command fails

VERSION=$1
RELEASE_TAG=$2
GITHUB_REPO=$3

mkdir -p UnityPackage/Plugins/Android/libs/arm64-v8a
mkdir -p UnityPackage/Plugins/iOS
mkdir -p UnityPackage/Plugins/macOS
mkdir -p UnityPackage/Plugins/Windows/x86_64
mkdir -p UnityPackage/Runtime
mkdir -p UnityPackage/Editor

# Copy Native Binaries (Heavy)
find artifacts/android-* -name "*.so" -exec cp {} UnityPackage/Plugins/Android/libs/arm64-v8a/ \; || true
find artifacts/iOS-* -name "*.a" -exec cp {} UnityPackage/Plugins/iOS/ \; || true
find artifacts/desktop-windows-*-Unity -name "*.dll" -exec cp {} UnityPackage/Plugins/Windows/x86_64/ \; || true
find artifacts/desktop-macos-*-Unity -name "*.dylib" -exec cp -R {} UnityPackage/Plugins/macOS/ \; || true

# Copy Source/Metadata
INCLUDE_DIR=$(find artifacts -type d -name "include" | head -n 1 || true)
if [ -n "$INCLUDE_DIR" ]; then cp -R "$INCLUDE_DIR"/* UnityPackage/Runtime; fi
cp -r UnityProject/extra/Editor/* UnityPackage/Editor/ || true
cp UnityProject/extra/ConnectedSpacesPlatform.Unity.Core.asmdef UnityPackage/Runtime/ || true

# Generate Package Metadata
CLEAN_VERSION="${VERSION#v}"
cmake -D "TEMPLATE=UnityProject/extra/package.json.template" \
      -D "OUTPUT=UnityPackage/package.json" \
      -D "VERSION=$CLEAN_VERSION" \
      -P cmake/GeneratePackageJson.cmake

echo '{
  "version": "'$VERSION'",
  "downloadUrl": "https://github.com/'$GITHUB_REPO'/releases/download/'$RELEASE_TAG'/com.magnopus.csp.unity-'$VERSION'.tgz"
}' > UnityPackage/package-dist.json