# The DocsExample directory within the repository (ayushshrivastv/OpenAPI-integration-with-DocC/DocsExample) is the source for this example.

## Building and Viewing Documentation Locally

1. Convert OpenAPI specification to SymbolGraph:
   ```
   swift run openapi-to-symbolgraph api.yaml --output-path api.symbolgraph.json
   ```

2. Generate DocC documentation:
   ```
   xcrun docc convert API.docc --fallback-display-name API --fallback-bundle-identifier com.example.API --fallback-bundle-version 1.0.0 --additional-symbol-graph-dir ./ --output-path ./docs
   ```

3. View the documentation locally:
   ```
   python -m http.server 8000 --directory docs
   ```

4. Open your browser to http://localhost:8000
