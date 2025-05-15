#!/bin/bash
# Script to install Swift on Ubuntu 22.04

# Download Swift
SWIFT_VERSION="5.9.2"
SWIFT_RELEASE="swift-${SWIFT_VERSION}-RELEASE"
SWIFT_PLATFORM="ubuntu22.04"
SWIFT_ARCHIVE="${SWIFT_RELEASE}-${SWIFT_PLATFORM}.tar.gz"
SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${SWIFT_PLATFORM}/${SWIFT_RELEASE}/${SWIFT_ARCHIVE}"

echo "Downloading Swift $SWIFT_VERSION..."
curl -O $SWIFT_URL

echo "Extracting Swift..."
tar xzf $SWIFT_ARCHIVE

echo "Setting up Swift in the PATH..."
mkdir -p $HOME/bin
export PATH=$PWD/${SWIFT_RELEASE}-${SWIFT_PLATFORM}/usr/bin:$PATH
echo "export PATH=$PWD/${SWIFT_RELEASE}-${SWIFT_PLATFORM}/usr/bin:\$PATH" >> $HOME/.bashrc

# Test Swift installation
echo "Testing Swift installation..."
swift --version

echo "Swift installation complete."
