# Core

This directory contains the core functionality and data models for the OpenAPI to SymbolGraph converter.

## Contents

- `HttpMethod.swift` - Enumeration of HTTP methods used in OpenAPI specifications
- `Mapping.swift` - Core mapping utilities for converting OpenAPI elements to SymbolKit symbols

## Responsibilities

The Core module is responsible for:

1. Defining fundamental data types used throughout the application
2. Providing core mapping functionality between OpenAPI and SymbolKit types
3. Maintaining a clean separation between the parsing and generation phases

This module has minimal dependencies and can be reused in different contexts. 
