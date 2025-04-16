# CLI Module

This module provides the command-line interface for converting OpenAPI specifications to DocC documentation.

## Usage

```bash
openapi-to-symbolgraph <input-file> --output-path <output-file>
```

## Features

- Convert OpenAPI YAML/JSON files to DocC symbol graphs
- Configurable output path
- Error handling and validation
- Progress reporting

## Contents

- `OpenAPItoSymbolGraph.swift` - Main CLI application using ArgumentParser

## Responsibilities

The CLI module is responsible for:

1. Defining the command-line interface and arguments
2. Parsing user input and validating arguments
3. Coordinating the workflow between different modules
4. Providing meaningful error messages and help text
5. Handling input/output file operations

This module leverages the Core and OpenAPItoSymbolGraph modules to perform the actual conversion. 
