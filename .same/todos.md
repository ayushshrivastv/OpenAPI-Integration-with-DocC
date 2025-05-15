# OpenAPI to DocC Integration Project Todos

## Phase 1: Core Functionality
- [x] Create a DocCCatalogGenerator that can generate .docc catalogs from OpenAPI specs
- [x] Update the CLI to support catalog generation
- [x] Create a convenience script for end-to-end documentation generation
- [x] Update README with new functionality documentation
- [x] Add support for OpenAPI examples in the generated documentation
- [ ] Improve schema documentation with property details
- [ ] Better handling of references in OpenAPI specs

## Phase 2: Integration with DocC Build Pipeline
- [ ] Improve error handling and reporting
- [ ] Add customization options for output (themes, templates, etc.)
- [ ] Add support for custom templates
- [ ] Enhance the API reference output with customizable sections

## Phase 3: Swift OpenAPI Generator Integration (Stretch Goal)
- [ ] Research Swift OpenAPI Generator plugin architecture
- [ ] Create a plugin for Swift OpenAPI Generator
- [ ] Ensure compatibility with generated Swift code
- [ ] Add integration tests with Swift OpenAPI Generator output

## Phase 4: VS Code Extension (Stretch Goal)
- [ ] Set up extension project structure
- [ ] Implement file watching for OpenAPI files
- [ ] Add conversion to DocC functionality
- [ ] Create a preview webview in VS Code
- [ ] Package and publish to VS Code marketplace

## Testing and Documentation
- [ ] Add tests for DocCCatalogGenerator
- [ ] Add tests for OpenAPI to DocC conversion with various specs
- [ ] Document the API for library users
- [ ] Create a tutorial for new users

## Bug Fixes and Improvements
- [ ] Fix handling of path parameters in URLs
- [ ] Improve rendering of complex schema types (arrays, maps, etc.)
- [ ] Add support for authentication information in the documentation
- [x] Better handling of markdown in OpenAPI description fields
