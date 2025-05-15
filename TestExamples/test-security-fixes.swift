#!/usr/bin/env swift

import Foundation

// This script tests the security scheme fixes by:
// 1. Parsing the test-api.yaml file
// 2. Verifying that security schemes are properly extracted
// 3. Testing the SwiftOpenAPIIntegration functionality with security schemes

// Run the OpenAPI to DocC conversion using our CLI tool
let process = Process()
let pipe = Pipe()

process.standardOutput = pipe
process.standardError = pipe
process.arguments = [
    "run",
    "openapi-to-docc",
    "generate-catalog",
    "--input", "../test-api.yaml",
    "--output", "TestOutput",
    "--module", "TestAPI"
]
process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")

do {
    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print("Command output:\n\(output)")
    }

    if process.terminationStatus == 0 {
        print("DocC catalog generated successfully")

        // Verify the contents of the generated files
        let fileManager = FileManager.default
        let catalogPath = "TestOutput/TestAPI.docc"

        if fileManager.fileExists(atPath: catalogPath) {
            print("Catalog directory exists at \(catalogPath)")

            // Check for specific files that should include security scheme documentation
            let symbolsFile = "\(catalogPath)/TestAPI.symbols.json"
            if fileManager.fileExists(atPath: symbolsFile) {
                print("Symbol graph file exists")

                // Read the file to check for security schemes
                if let data = fileManager.contents(atPath: symbolsFile),
                   let jsonString = String(data: data, encoding: .utf8) {
                    if jsonString.contains("bearerAuth") &&
                       jsonString.contains("apiKeyAuth") &&
                       jsonString.contains("oauth2Auth") {
                        print("✅ Security schemes found in symbol graph file")
                    } else {
                        print("❌ Security schemes not found in symbol graph file")
                    }
                }
            } else {
                print("❌ Symbol graph file does not exist")
            }

            // Check for main documentation file
            let mainFile = "\(catalogPath)/TestAPI.md"
            if fileManager.fileExists(atPath: mainFile) {
                print("Main documentation file exists")

                // Read the file to check for authentication section
                if let data = fileManager.contents(atPath: mainFile),
                   let content = String(data: data, encoding: .utf8) {
                    if content.contains("Authentication") {
                        print("✅ Authentication section found in main documentation")
                    } else {
                        print("❌ Authentication section not found in main documentation")
                    }
                }
            } else {
                print("❌ Main documentation file does not exist")
            }
        } else {
            print("❌ Catalog directory does not exist")
        }
    } else {
        print("Error: Process exited with status \(process.terminationStatus)")
    }
} catch {
    print("Error: \(error.localizedDescription)")
}
