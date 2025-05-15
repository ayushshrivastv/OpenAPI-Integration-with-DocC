# Changelog

## v1.1.0 - 2025-05-15

### Fixed
- Fixed duplicate `getSchemaExample` function in DocCCatalogGenerator.swift
- Fixed syntax errors in DocCCatalogGenerator.swift (missing closing brackets)
- Fixed build issues preventing `swift build` from successfully compiling
- Fixed missing implementation of `generateSchemaDocumentationFiles` in DocCCatalogGenerator

### Added
- Complete Swift OpenAPI Generator integration with enhanced type mapping
- Added support for authentication information in the documentation
- Added comprehensive tutorial for new users (Documentation/Tutorials/OpenAPItoDocCTutorial.md)
- Added support for custom templates and theming options
- Added robust handling of complex OpenAPI specifications and edge cases:
  - Support for string formats (date, uuid, email, uri, etc.)
  - Improved handling of reference types
  - Support for dictionary types (additionalProperties)
  - Enhanced handling of composite types (allOf, anyOf, oneOf)
  - Better documentation for enum types

### Improved
- Enhanced type mapping for OpenAPI schemas to Swift types
- Improved documentation generation with better type descriptions
- Added more detailed handling of authentication methods

## v1.0.0 - 2025-04-15

### Initial Release
- Basic conversion of OpenAPI specifications to DocC documentation
- Support for documenting endpoints, schemas, parameters, and more
- Symbol Graph debugging tool for troubleshooting
- Command-line interface for generating documentation
