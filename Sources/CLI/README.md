# CLI

This directory contains the command-line interface for the OpenAPI to SymbolGraph converter.

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
