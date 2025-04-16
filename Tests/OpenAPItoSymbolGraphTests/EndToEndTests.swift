import XCTest
import Foundation
import OpenAPIKit
import SymbolKit
import Yams
import ArgumentParser
@testable import Core
@testable import CLI
@testable import OpenAPItoSymbolGraph

final class EndToEndTests: XCTestCase {
    var tempDir: URL!
    var testYamlPath: String!
    var outputPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create a temporary directory for test artifacts
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
        
        // Create a sample YAML file
        testYamlPath = tempDir.appendingPathComponent("test.yaml").path
        let yamlContent = """
        openapi: 3.1.0
        info:
          title: Test API
          version: 1.0.0
        paths:
          /test:
            get:
              summary: Test endpoint
              operationId: getTest
              responses:
                '200':
                  description: OK
        """
        try yamlContent.write(toFile: testYamlPath, atomically: true, encoding: .utf8)
        
        // Define the output path
        outputPath = tempDir.appendingPathComponent("output.symbolgraph.json").path
    }

    override func tearDownWithError() throws {
        // Clean up the temporary directory
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        testYamlPath = nil
        outputPath = nil
        try super.tearDownWithError()
    }

    // Test successful conversion of a simple YAML file
    func testSuccessfulConversion() throws {
        // Run the command
        let arguments = [testYamlPath!, "--output-path", outputPath!]
        let command = try OpenAPItoSymbolGraphCommand.parse(arguments)
        try command.run()
        
        // Check if the output file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath!), "Output symbol graph file should exist")
        
        // Decode the output file
        let outputData = try Data(contentsOf: URL(fileURLWithPath: outputPath!))
        let decoder = JSONDecoder()
        let symbolGraph = try decoder.decode(SymbolKit.SymbolGraph.self, from: outputData)
        
        // Basic assertions on the symbol graph
        XCTAssertEqual(symbolGraph.module.name, "TestAPI")
        XCTAssertEqual(symbolGraph.symbols.count, 2, "Should contain namespace and endpoint symbols")
        XCTAssertEqual(symbolGraph.relationships.count, 1, "Should contain one memberOf relationship")
    }

    // Test command-line argument parsing
    func testArgumentParsing() throws {
        // Create an instance of the command (assuming it's now OpenAPItoSymbolGraphCommand)
        var cmd = try OpenAPItoSymbolGraphCommand.parse(["some/path.yaml"])
        XCTAssertEqual(cmd.inputPath, "some/path.yaml")
        XCTAssertEqual(cmd.outputPath, "openapi.symbolgraph.json") // Default output path

        cmd = try OpenAPItoSymbolGraphCommand.parse(["another.json", "--output-path", "custom.json"])
        XCTAssertEqual(cmd.inputPath, "another.json")
        XCTAssertEqual(cmd.outputPath, "custom.json")
    }

    // Test handling of invalid file type
    func testInvalidFileType() throws {
        let invalidFilePath = tempDir.appendingPathComponent("test.txt").path
        try "invalid content".write(toFile: invalidFilePath, atomically: true, encoding: .utf8)
        
        let arguments = [invalidFilePath, "--output-path", outputPath!]
        let command = try OpenAPItoSymbolGraphCommand.parse(arguments)
        
        XCTAssertThrowsError(try command.run()) {
            error in
            if let conversionError = error as? ConversionError,
               case .invalidFileType(let message) = conversionError {
                XCTAssertTrue(message.contains("Unsupported file type: txt"), "Error message should indicate unsupported file type")
            } else {
                XCTFail("Expected ConversionError.invalidFileType, but got \(error)")
            }
        }
    }
} 
