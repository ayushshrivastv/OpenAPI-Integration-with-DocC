#!/bin/bash
# Script to prepare and serve the documentation for local testing

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

# Start the server directly from the docs directory
echo "Starting local preview server on port $PORT..."
echo "Open your browser to http://localhost:$PORT/"
echo "You should be automatically redirected to the API documentation."
python3 -m http.server $PORT --directory docs
