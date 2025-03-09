#!/bin/bash

# Create artifactory temporary directory
mkdir -p artifactory_tmp

# Create demo versions if they don't exist
mkdir -p demo/1.0.0 demo/1.0.1 demo/1.0.2

# Create sample content if it doesn't exist
[ ! -f demo/1.0.0/index.html ] && echo "<html><body><h1>Version 1.0.0</h1></body></html>" > demo/1.0.0/index.html
[ ! -f demo/1.0.1/index.html ] && echo "<html><body><h1>Version 1.0.1</h1></body></html>" > demo/1.0.1/index.html
[ ! -f demo/1.0.2/index.html ] && echo "<html><body><h1>Version 1.0.2</h1></body></html>" > demo/1.0.2/index.html

# Function to wait for Artifactory to be ready
wait_for_artifactory() {
    echo "Waiting for Artifactory to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -u admin:password http://localhost:8081/artifactory/api/system/ping >/dev/null; then
            echo "Artifactory is ready!"
            return 0
        fi
        echo "Attempt $attempt of $max_attempts. Still waiting..."
        sleep 20
        attempt=$((attempt + 1))
    done
    
    echo "Artifactory failed to start after $max_attempts attempts"
    return 1
}

# Function to create repository if it doesn't exist
create_repository() {
    echo "Creating repository if it doesn't exist..."
    curl -u admin:password -X PUT "http://localhost:8081/artifactory/api/repositories/versioned-assets" \
        -H "Content-Type: application/json" \
        -d '{"key": "versioned-assets","rclass": "local","packageType": "generic"}' || true
}

# Package versions
echo "Creating archives..."
cd demo/1.0.0 && tar -czf ../../1.0.0.tar.gz . && cd ../..
cd demo/1.0.1 && tar -czf ../../1.0.1.tar.gz . && cd ../..
cd demo/1.0.2 && tar -czf ../../1.0.2.tar.gz . && cd ../..

# Start Artifactory if it's not running
if ! docker ps | grep -q artifactory; then
    echo "Starting Artifactory..."
    docker-compose up -d artifactory
    wait_for_artifactory
    create_repository
fi

# Upload archives to Artifactory
echo "Uploading archives to Artifactory..."
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.0.tar.gz" -T 1.0.0.tar.gz
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.1.tar.gz" -T 1.0.1.tar.gz
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.2.tar.gz" -T 1.0.2.tar.gz

echo "Setup complete! You can now:"
echo "1. Start nginx container: docker-compose up -d nginx-versions"
echo "2. Access versions at:"
echo "   - http://localhost/1.0.0"
echo "   - http://localhost/1.0.1"
echo "   - http://localhost/1.0.2"
