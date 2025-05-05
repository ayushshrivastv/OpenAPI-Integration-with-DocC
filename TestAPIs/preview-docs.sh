#!/bin/bash

# Define port
PORT=8080

# Kill any existing preview servers
pkill -f "docc preview" 2>/dev/null

# Start the preview server in the background
# The paths are relative to the TestAPIs directory where the script is run
xcrun docc preview Petstore.docc --additional-symbol-graph-dir . --port $PORT &
SERVER_PID=$!

# Wait a moment for the server to start
sleep 2

# Display URLs
echo "========================================"
echo "Documentation URLs:"
echo "- Petstore API: http://localhost:$PORT/documentation/swagger-petstore---openapi-3.0"
echo "- GitHub API: http://localhost:$PORT/documentation/github-v3-rest-api"
echo "========================================"

# Open browser automatically to Petstore documentation
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://localhost:$PORT/documentation/swagger-petstore---openapi-3.0"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "http://localhost:$PORT/documentation/swagger-petstore---openapi-3.0"
fi

echo "Press Ctrl+C to stop the preview server"

# Wait for user to press Ctrl+C
wait $SERVER_PID 
