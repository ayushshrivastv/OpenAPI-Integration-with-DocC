# Troubleshooting Guide

This document provides solutions for common issues you might encounter when building and using the OpenAPI Integration with DocC project.

## Swift Build Errors

### Missing Swift Command

**Error:** `bash: swift: command not found`

**Solution:**
- Swift is not installed or not in your PATH
- Use the provided `scripts/install-swift.sh` script to install Swift
- For manual installation, visit [Swift.org](https://swift.org/download/)

### Package Dependencies Resolution Failure

**Error:** `error: failed to retrieve dependencies: fatal: unable to access 'https://github.com/...'`

**Solution:**
- Check your internet connection
- If you're behind a proxy, configure git to use it:
  ```bash
  git config --global http.proxy http://your-proxy:port
  ```
- Try manually cloning the specific dependency that's failing

### Compilation Errors

**Error:** `error: value of type 'X' has no member 'Y'`

**Solution:**
- This often happens when using an incompatible version of a dependency
- Check if your Swift version matches the required version (Swift 5.9+)
- Run `swift package update` to update dependencies
- Delete the `.build` directory and try again: `rm -rf .build && swift build`

### Symbol Not Found Errors

**Error:** `symbol not found: _...'`

**Solution:**
- This typically happens when linking against an incompatible library version
- Make sure all dependencies are properly resolved
- On macOS, try using a specific Swift toolchain version from [Swift.org](https://swift.org/download/)

## DocC Generation Errors

### JSON Schema Parsing Errors

**Error:** `error: failed to parse OpenAPI specification: invalid JSON in ...`

**Solution:**
- Verify your OpenAPI specification is valid
- Use an online validator like [Swagger Editor](https://editor.swagger.io/)
- Check for syntax errors in your YAML or JSON file

### Missing References

**Error:** `error: reference not found: #/components/schemas/...`

**Solution:**
- Ensure all references in your OpenAPI specification are valid
- Check for typos in schema names
- Make sure referenced components actually exist in your specification

### Template Rendering Errors

**Error:** `error: unable to render template: ...`

**Solution:**
- If using custom templates, verify they are properly formatted
- Make sure the template directory exists and is readable
- Check for syntax errors in your template files

## Runtime Errors

### Security Permission Issues

**Error:** `error: could not create output directory: permission denied`

**Solution:**
- Ensure you have write permissions to the output directory
- Run the command with appropriate permissions:
  ```bash
  sudo chown -R $(whoami) /path/to/output
  ```
  or use a directory in your home folder instead

### Memory Limitations

**Error:** `Killed: 9` or process silently terminates

**Solution:**
- Your system might be running out of memory when processing large OpenAPI files
- Try increasing swap space
- Break your OpenAPI specification into smaller files
- Use the `--memory-limit` flag if available

## Additional Tips

### Debugging Build Issues

For more detailed build output, use:
```bash
swift build -v
```

To clean the build directory and start fresh:
```bash
swift package clean
swift build
```

### Checking Swift Package Dependencies

To see all resolved dependencies:
```bash
swift package show-dependencies
```

To update dependencies to their latest compatible versions:
```bash
swift package update
```

### Common OpenAPI Specification Issues

- Ensure your OpenAPI specification is valid (version 3.0+)
- Check that all required fields are present
- Validate that schema references are correctly formed
- Make sure authentication information is properly structured

If you continue to experience issues after trying these solutions, please open an issue on the GitHub repository with detailed information about your problem, including:

1. Your operating system and Swift version
2. Complete error message and stack trace
3. Steps to reproduce the issue
4. Any modifications you've made to the code
