# OpenAPItoSymbolGraph

This directory contains the main implementation of the OpenAPI to SymbolGraph converter.

## Structure

- `OpenAPItoSymbolGraph.swift` - Main conversion logic
- `Core/` - Core types and utilities used by the converter (Mirror from top-level Core)
- `CLI/` - Command-line interface implementation (Mirror from top-level CLI)
- `Mapping/` - Types and utilities for mapping OpenAPI elements to SymbolGraph format
- `Utils/` - Additional utilities for various aspects of the conversion process
  - `DocC/` - Utilities for generating DocC documentation from SymbolGraph files

## Responsibilities

The OpenAPItoSymbolGraph module is responsible for:

1. Converting OpenAPI specifications to SymbolGraph format
2. Coordinating between different components of the conversion process
3. Providing a clean API for integration with other tools
4. Managing the mapping between OpenAPI concepts and DocC documentation concepts
5. Generating high-quality documentation that integrates well with Swift documentation

This module serves as the central hub for the conversion process. 
