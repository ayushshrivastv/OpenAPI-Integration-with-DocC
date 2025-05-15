#!/bin/bash
# Script to install Swift for OpenAPI Integration with DocC project
# Usage: bash install-swift.sh

set -e

# Determine OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Detected macOS system."
    echo "Checking if Xcode is installed..."

    if xcode-select -p &>/dev/null; then
        echo "Xcode is installed."
    else
        echo "Xcode is not installed. Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "Please complete the Xcode Command Line Tools installation and run this script again."
        exit 1
    fi

    echo "Checking Swift version..."
    if command -v swift &>/dev/null; then
        SWIFT_VERSION=$(swift --version | head -n 1)
        echo "Swift is already installed: $SWIFT_VERSION"
    else
        echo "Swift not found. Please ensure Xcode is properly installed."
        echo "You can also download a specific Swift toolchain from https://swift.org/download/"
        exit 1
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Detected Linux system."
    DISTRO=$(lsb_release -is 2>/dev/null || cat /etc/os-release | grep -oP '(?<=^ID=).+' | tr -d '"')
    VERSION=$(lsb_release -rs 2>/dev/null || cat /etc/os-release | grep -oP '(?<=^VERSION_ID=).+' | tr -d '"')
    ARCH=$(uname -m)

    echo "Distribution: $DISTRO"
    echo "Version: $VERSION"
    echo "Architecture: $ARCH"

    if [[ "$DISTRO" == "Ubuntu" ]]; then
        echo "Installing dependencies for Ubuntu..."
        sudo apt-get update
        sudo apt-get install -y \
            binutils \
            git \
            gnupg2 \
            libc6-dev \
            libcurl4 \
            libedit2 \
            libgcc-9-dev \
            libpython3.8 \
            libsqlite3-0 \
            libstdc++-9-dev \
            libxml2 \
            libz3-dev \
            pkg-config \
            tzdata \
            unzip \
            zlib1g-dev

        # Map Ubuntu version to Swift download
        if [[ "$VERSION" == "20.04" ]]; then
            SWIFT_URL="https://download.swift.org/swift-5.9.2-release/ubuntu2004/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu20.04.tar.gz"
        elif [[ "$VERSION" == "22.04" ]]; then
            SWIFT_URL="https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz"
        elif [[ "$VERSION" == "24.04" ]]; then
            # For newer Ubuntu, try the closest version
            SWIFT_URL="https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz"
            echo "Warning: Swift doesn't have an official release for Ubuntu 24.04 yet. Using Ubuntu 22.04 version."
        else
            echo "Unsupported Ubuntu version: $VERSION"
            echo "Please check https://swift.org/download/ for available versions"
            exit 1
        fi

        # Handle ARM vs x86_64
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            SWIFT_URL="${SWIFT_URL/\.tar\.gz/-aarch64.tar.gz}"
        fi

    elif [[ "$DISTRO" == "Debian" ]]; then
        echo "Installing dependencies for Debian..."
        sudo apt-get update
        sudo apt-get install -y \
            binutils \
            git \
            gnupg2 \
            libc6-dev \
            libcurl4 \
            libedit2 \
            libgcc-9-dev \
            libpython3-dev \
            libsqlite3-0 \
            libstdc++-9-dev \
            libxml2 \
            libz3-dev \
            pkg-config \
            tzdata \
            unzip \
            zlib1g-dev

        echo "For Debian, please download Swift from https://swift.org/download/"
        echo "This script doesn't automatically install Swift on Debian."
        exit 1

    elif [[ "$DISTRO" == "CentOS" || "$DISTRO" == "RHEL" || "$DISTRO" == "Fedora" ]]; then
        echo "Installing dependencies for CentOS/RHEL/Fedora..."
        sudo yum install -y \
            binutils \
            gcc \
            git \
            glibc-static \
            libbsd-devel \
            libedit \
            libedit-devel \
            libicu-devel \
            libstdc++-static \
            pkg-config \
            python3-devel \
            sqlite \
            zlib-devel

        echo "For CentOS/RHEL/Fedora, please download Swift from https://swift.org/download/"
        echo "This script doesn't automatically install Swift on CentOS/RHEL/Fedora."
        exit 1

    else
        echo "Unsupported Linux distribution: $DISTRO"
        echo "Please check https://swift.org/download/ for installation instructions"
        exit 1
    fi

    if [ -n "$SWIFT_URL" ]; then
        echo "Downloading Swift from $SWIFT_URL"
        wget -O swift.tar.gz $SWIFT_URL

        echo "Extracting Swift..."
        sudo mkdir -p /opt/swift
        sudo tar -xzf swift.tar.gz -C /opt/swift --strip-components=1

        echo "Setting up Swift in PATH..."
        echo 'export PATH="/opt/swift/usr/bin:$PATH"' | sudo tee /etc/profile.d/swift.sh

        echo "Cleaning up..."
        rm swift.tar.gz

        # Source the profile script to update current session
        source /etc/profile.d/swift.sh

        echo "Swift installation complete. Please check version:"
        swift --version
    fi

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Detected Windows system."
    echo "Swift on Windows is best used with WSL (Windows Subsystem for Linux)."
    echo "Please install WSL and Ubuntu, then run this script again from within WSL."
    echo "Alternatively, visit https://swift.org/download/ for Windows-specific instructions."
    exit 1

else
    echo "Unsupported operating system: $OSTYPE"
    echo "Please visit https://swift.org/download/ for installation instructions"
    exit 1
fi

# Final checks
echo
echo "Checking Swift installation..."
if command -v swift &>/dev/null; then
    echo "Swift is installed:"
    swift --version

    echo
    echo "Building OpenAPI Integration with DocC project..."
    cd "$(dirname "$0")/.." || exit 1
    swift build

    if [ $? -eq 0 ]; then
        echo
        echo "Build successful! You can now use the OpenAPI Integration with DocC tool."
        echo "Try converting an example OpenAPI specification to DocC documentation:"
        echo "./scripts/generate-openapi-docc.sh Examples/petstore.yaml"
    else
        echo
        echo "Build failed. Please check the error messages above."
    fi
else
    echo "Swift installation could not be verified. Please ensure it's in your PATH."
    exit 1
fi
