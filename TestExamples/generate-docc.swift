#!/usr/bin/env swift

import Foundation

// Run the OpenAPI to DocC conversion using our CLI tool
let process = Process()
let pipe = Pipe()

process.standardOutput = pipe
process.standardError = pipe
process.arguments = [
    "run",
    "openapi-to-docc",
    "generate-catalog",
    "--input", "TestExamples/petstore-openapi3.yaml",
    "--output", "TestOutput",
    "--module", "PetStore"
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
    } else {
        print("Error: Process exited with status \(process.terminationStatus)")
    }
} catch {
    print("Error: \(error.localizedDescription)")
}
