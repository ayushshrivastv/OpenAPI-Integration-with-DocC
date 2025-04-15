#!/bin/bash
# Script to serve the documentation locally

# Function to check if a port is in use
is_port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
    return $?
}

# Try different ports
PORT=8000
MAX_PORT=8010

while [ $PORT -le $MAX_PORT ]; do
    if ! is_port_in_use $PORT; then
        break
    fi
    echo "Port $PORT is in use, trying next port..."
    PORT=$((PORT + 1))
done

if [ $PORT -gt $MAX_PORT ]; then
    echo "Error: Could not find an available port between 8000 and $MAX_PORT"
    exit 1
fi

# Check if python3 is available
if command -v python3 &> /dev/null; then
    echo "Starting server with python3 on port $PORT..."
    python3 -m http.server $PORT --directory docs
# Check if python is available as a fallback
elif command -v python &> /dev/null; then
    # Check Python version to ensure it's Python 3
    PYTHON_VERSION=$(python --version 2>&1)
    if [[ $PYTHON_VERSION == *"Python 3"* ]]; then
        echo "Starting server with python on port $PORT..."
        python -m http.server $PORT --directory docs
    else
        echo "Error: Python 3 is required to run the server."
        exit 1
    fi
else
    echo "Error: Python 3 is not installed. Please install Python 3 to run the server."
    exit 1
fi 
