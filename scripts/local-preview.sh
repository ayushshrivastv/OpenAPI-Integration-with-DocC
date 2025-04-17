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

# Create the local testing directory structure
echo "Setting up local testing environment..."
mkdir -p docs-local/OpenAPI-Integration-with-DocC
cp -r docs/* docs-local/OpenAPI-Integration-with-DocC/

# Create redirect index.html if it doesn't exist
if [ ! -f docs-local/index.html ]; then
    cat > docs-local/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="0; url=OpenAPI-Integration-with-DocC/">
    <title>Redirecting to API Documentation</title>
</head>
<body>
    <p>If you are not redirected automatically, <a href="OpenAPI-Integration-with-DocC/">click here</a>.</p>
</body>
</html>
EOF
    echo "Created redirect index.html in docs-local/"
fi

# Start the server
echo "Starting local preview server on port $PORT..."
echo "Open your browser to http://localhost:$PORT/"
python3 -m http.server $PORT --directory docs-local 
