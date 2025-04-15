#!/bin/bash
# Script to serve the documentation locally

# Check if python3 is available
if command -v python3 &> /dev/null; then
    echo "Starting server with python3..."
    python3 -m http.server 8000 --directory docs
# Check if python is available as a fallback
elif command -v python &> /dev/null; then
    # Check Python version to ensure it's Python 3
    PYTHON_VERSION=$(python --version 2>&1)
    if [[ $PYTHON_VERSION == *"Python 3"* ]]; then
        echo "Starting server with python..."
        python -m http.server 8000 --directory docs
    else
        echo "Error: Python 3 is required to run the server."
        exit 1
    fi
else
    echo "Error: Python 3 is not installed. Please install Python 3 to run the server."
    exit 1
fi 
