#!/bin/bash

# Check system architecture
arch

# Remove directories (force + recursive)
rm -rf ../../build
rm -rf ../../install

# Configure with CMake
cmake -S ../../ -B ../../build -DENABLE_UNITY_EXTENSIONS=ON -DCMAKE_OSX_ARCHITECTURES="arm64" -DENABLE_THROW_EXCEPTION_ON_RESULTBASE_FAILURE=ON

# Build (Debug is default unless generator supports configs)
cmake --build ../../build --config Debug

# Install
cmake --install ../../build --config Debug

# Generate Unity package
cmake --build ../../build --target AssembleUnityLocal --config Debug