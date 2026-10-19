#!/bin/bash

# Check system architecture
arch

# Absolute path to the repo root, so conan and cmake agree on where the build folder is regardless of the cwd
ROOT_DIR="$(cd ../.. && pwd)"

# Remove directories (force + recursive)
rm -rf ../../build
rm -rf ../../install

#Download packages
conan install ../../ --output-folder="$ROOT_DIR/build" --build=missing  -s build_type=Debug --profile:host=../../profiles/host/ios_arm64

# Configure with CMake
cmake -S ../../ -B ../../build -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_ARCHITECTURES="arm64" -DBUILD_SHARED_LIBS=OFF -DENABLE_UNITY_EXTENSIONS=ON -DCMAKE_TOOLCHAIN_FILE="$ROOT_DIR/build/conan_toolchain.cmake" -DCSP_BUILD_TYPE=Debug

# Build (Debug is default unless generator supports configs)
cmake --build ../../build --config Debug

# Install
cmake --install ../../build --config Debug
