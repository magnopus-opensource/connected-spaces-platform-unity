#!/bin/bash

# Check system architecture
arch

# Remove directories (force + recursive)
rm -rf ../../build
rm -rf ../../install

# Configure with CMake
cmake -S ../../ -B ../../build -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_ARCHITECTURES="arm64" -DBUILD_SHARED_LIBS=OFF -DENABLE_UNITY_EXTENSIONS=ON

# Build (Debug is default unless generator supports configs)
cmake --build ../../build --config Debug

# Install
cmake --install ../../build --config Debug
