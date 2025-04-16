import XCTest
@testable import OpenAPItoSymbolGraph
@testable import OpenAPI

final class RegistryTests: XCTestCase {
    func testParseRegistrySpec() throws {
        let parser = YAMLParser()
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("registry.openapi.yaml")
        let document = try parser.parse(fileURL: fileURL)
        
        // Verify basic document structure
        XCTAssertEqual(document.openapi, "3.0.3")
        XCTAssertEqual(document.info.title, "Swift Package Registry API")
        XCTAssertEqual(document.info.version, "1.0.0")
        
        // Verify paths
        XCTAssertNotNil(document.paths["/{scope}/{name}"])
        XCTAssertNotNil(document.paths["/{scope}/{name}/{version}"])
        XCTAssertNotNil(document.paths["/{scope}/{name}/{version}/Package.swift"])
        
        // Verify components
        XCTAssertNotNil(document.components)
        XCTAssertNotNil(document.components?.schemas)
        
        // Verify schemas
        let schemas = document.components?.schemas
        XCTAssertNotNil(schemas?["PackageMetadata"])
        XCTAssertNotNil(schemas?["ReleaseMetadata"])
        XCTAssertNotNil(schemas?["ProblemDetails"])
        
        // Verify parameters
        XCTAssertNotNil(document.components?.parameters)
        let parameters = document.components?.parameters
        XCTAssertNotNil(parameters?["Scope"])
        XCTAssertNotNil(parameters?["PackageName"])
    }
} 
