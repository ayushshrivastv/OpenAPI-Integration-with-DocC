# Building and Testing the Project

This document provides detailed instructions for building and testing the OpenAPI Integration with DocC project on different platforms.

## Prerequisites

- **Swift 5.9** or later
- **Git** (for cloning the repository and dependencies)
- A **terminal/command line** application
- **Internet connection** (for downloading dependencies)

## Installing Swift

### Easy Installation

We've included a script that automatically installs Swift for your platform:

```bash
./scripts/install-swift.sh
```

This script will detect your operating system, install the necessary dependencies, and set up Swift appropriately.

### Manual Installation

#### macOS

1. **Using Xcode (Recommended for macOS users):**
   - Download and install Xcode from the Mac App Store
   - Open Xcode and agree to the license terms
   - Install the Command Line Tools:
     ```bash
     xcode-select --install
     ```

2. **Using Swift Toolchain (for a specific Swift version):**
   - Visit [Swift.org Downloads](https://swift.org/download/)
   - Download the Swift toolchain for macOS
   - Run the installer and follow the instructions
   - Set up your PATH:
     ```bash
     echo 'export PATH="/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH"' >> ~/.zshrc
     source ~/.zshrc
     ```

#### Linux (Ubuntu)

```bash
# Install dependencies
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

# Download and install Swift
wget https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
sudo mkdir -p /opt/swift
sudo tar -xzf swift-5.9.2-RELEASE-ubuntu22.04.tar.gz -C /opt/swift --strip-components=1
echo 'export PATH="/opt/swift/usr/bin:$PATH"' | sudo tee /etc/profile.d/swift.sh
source /etc/profile.d/swift.sh
```

Note: Adjust the download URL for your Ubuntu version and architecture.

#### Windows (using WSL)

1. Install Windows Subsystem for Linux (WSL):
   ```powershell
   wsl --install -d Ubuntu
   ```

2. Open Ubuntu WSL and follow the Linux installation instructions above.

## Building the Project

Once Swift is installed, you can build the project:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/ayushshrivastv/OpenAPI-Integration-with-DocC.git
cd OpenAPI-Integration-with-DocC

# Build the project
swift build
```

The build process will:
1. Resolve and download all dependencies
2. Compile the source code
3. Link the executable

### Debug Build

For a debug build with more information (default):

```bash
swift build -c debug
```

### Release Build

For an optimized release build:

```bash
swift build -c release
```

### Build for a Specific Platform

To build for a specific platform:

```bash
swift build --build-tests --target-platform macos
```

Replace `macos` with your target platform (`ios`, `linux`, etc.).

## Testing the Project

To run the tests:

```bash
swift test
```

### Running Specific Tests

To run a specific test:

```bash
swift test --filter OpenAPItoSymbolGraphTests/PetstoreTests
```

### Testing with Code Coverage

To generate code coverage reports:

```bash
swift test --enable-code-coverage
```

## Common Build Errors and Solutions

### Missing Dependencies

If you see errors about missing dependencies, try running:

```bash
swift package update
```

### Compilation Errors

If you encounter compilation errors:
1. Make sure you're using Swift 5.9 or later: `swift --version`
2. Clean the build directory: `swift package clean`
3. Check for syntax errors in the file mentioned in the error message
4. See if you're using the latest dependencies: `swift package update`

### Linker Errors

For linker errors:
1. Check if all dependencies are properly resolved
2. Ensure your Swift version matches the required version
3. Try deleting the `.build` directory and rebuilding: `rm -rf .build && swift build`

For more troubleshooting information, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Using the Built Executable

After a successful build, you can find the executable at:

- Debug build: `.build/debug/openapi-to-symbolgraph`
- Release build: `.build/release/openapi-to-symbolgraph`

You can run it directly:

```bash
.build/debug/openapi-to-symbolgraph to-docc Examples/petstore.yaml --output-directory ./output
```

Or use the convenience scripts:

```bash
./scripts/generate-openapi-docc.sh Examples/petstore.yaml
```

## Development Tips

- Use `swift build -v` for verbose build output
- Use `swift package show-dependencies` to verify dependencies
- For development, you might want to add `.build/debug` to your PATH:
  ```bash
  export PATH="$(pwd)/.build/debug:$PATH"
  ```
- Use the debug build during development for better error messages

If you continue to encounter issues, please check the [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) guide or open an issue on GitHub.
