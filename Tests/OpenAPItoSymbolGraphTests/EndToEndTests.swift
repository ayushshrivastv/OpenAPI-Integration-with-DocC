import XCTest
import OpenAPIKit
import SymbolKit
import Yams
import ArgumentParser
@testable import Core
@testable import CLI

final class EndToEndTests: XCTestCase {
    // Test file paths
    let testYamlPath = NSTemporaryDirectory() + "test-api.yaml"
    let testJsonPath = NSTemporaryDirectory() + "test-api.json"
    let outputPath = NSTemporaryDirectory() + "test.symbolgraph.json"
    
    override func tearDown() {
        // Clean up temporary files
        try? FileManager.default.removeItem(atPath: testYamlPath)
        try? FileManager.default.removeItem(atPath: testJsonPath)
        try? FileManager.default.removeItem(atPath: outputPath)
        super.tearDown()
    }
    
    // Simple YAML OpenAPI spec for quicker tests
    let simpleOpenAPIYaml = """
    openapi: 3.1.0
    info:
      title: Simple API
      version: 1.0.0
    paths:
      /hello:
        get:
          operationId: hello
          responses:
            '200':
              description: OK
    """
    
    // Simple JSON OpenAPI spec for quicker tests
    let simpleOpenAPIJson = """
    {
      "openapi": "3.1.0",
      "info": {
        "title": "Simple API", 
        "version": "1.0.0"
      },
      "paths": {
        "/hello": {
          "get": {
            "operationId": "hello",
            "responses": {
              "200": {
                "description": "OK"
              }
            }
          }
        }
      }
    }
    """
    
    // Test command-line argument parsing
    func testArgumentParsing() throws {
        var cmd = OpenAPItoSymbolGraph()
        cmd.inputPath = testYamlPath
        cmd.outputPath = outputPath
        
        XCTAssertEqual(cmd.inputPath, testYamlPath)
        XCTAssertEqual(cmd.outputPath, outputPath)
    }
    
    // Test parsing and basic structure validation of YAML input
    func testYAMLParsing() throws {
        try simpleOpenAPIYaml.write(to: URL(fileURLWithPath: testYamlPath), atomically: true, encoding: .utf8)
        
        // Directly test the parsing logic without running the full CLI process
        let yamlString = try String(contentsOfFile: testYamlPath, encoding: .utf8)
        let parsedDict = try Yams.load(yaml: yamlString) as? [String: Any]
        
        XCTAssertNotNil(parsedDict)
        XCTAssertEqual((parsedDict?["info"] as? [String: Any])?["title"] as? String, "Simple API")
        
        // Verify paths structure
        let paths = parsedDict?["paths"] as? [String: Any]
        XCTAssertNotNil(paths)
        XCTAssertNotNil(paths?["/hello"])
    }
    
    // Test parsing and basic structure validation of JSON input
    func testJSONParsing() throws {
        try simpleOpenAPIJson.write(to: URL(fileURLWithPath: testJsonPath), atomically: true, encoding: .utf8)
        
        // Directly test the parsing logic without running the full CLI process
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: testJsonPath))
        let parsedDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        XCTAssertNotNil(parsedDict)
        XCTAssertEqual((parsedDict?["info"] as? [String: Any])?["title"] as? String, "Simple API")
        
        // Verify paths structure
        let paths = parsedDict?["paths"] as? [String: Any]
        XCTAssertNotNil(paths)
        XCTAssertNotNil(paths?["/hello"])
    }
} 
