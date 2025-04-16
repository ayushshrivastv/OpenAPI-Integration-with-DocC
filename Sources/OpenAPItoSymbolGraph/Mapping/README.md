# Mapping

This directory contains classes and utilities for mapping between OpenAPI elements and SymbolGraph symbols.

## Contents

- `SymbolMapping.swift` - Main mapping implementation for OpenAPI to SymbolGraph

## Responsibilities

The Mapping module is responsible for:

1. Converting OpenAPI schemas to SymbolGraph types
2. Mapping HTTP operations to function symbols
3. Creating appropriate relationships between symbols
4. Generating comprehensive documentation from OpenAPI metadata
5. Handling special cases and edge conditions in the mapping process

This module is the core of the conversion process, translating OpenAPI concepts to DocC-friendly symbols. 
