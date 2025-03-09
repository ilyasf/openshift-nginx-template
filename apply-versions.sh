#!/bin/bash

# Create temporary directory for versions
mkdir -p /tmp/versions

# Read and parse package.json
VERSIONS_CONFIG=$(grep -o '"versionsConfig":{[^}]*}' package.json)
ARTIFACTORY_PATH=$(echo "$VERSIONS_CONFIG" | grep -o '"artifactoryPath":"[^"]*"' | cut -d'"' -f4)

echo "ARTIFACTORY_PATH: $ARTIFACTORY_PATH"

# If ARTIFACTORY_URL is set, use it instead of localhost
if [ ! -z "$ARTIFACTORY_URL" ]; then
    ARTIFACTORY_PATH="${ARTIFACTORY_URL#http://}/artifactory/versioned-assets/web-assets"
fi

# Extract versions array
VERSIONS_ARRAY=$(sed -n '/\"versions\":\s*\[/,/\]/p' package.json)

# Parse each version
echo "$VERSIONS_ARRAY" | grep -o '"version":"[^"]*"' | cut -d'"' -f4 | while read -r VERSION; do
    if [ ! -z "$VERSION" ]; then
        echo "Processing version: $VERSION"
        
        # Create directory for version
        mkdir -p "/tmp/versions/$VERSION"
        
        # Download archive
        curl -s "https://${ARTIFACTORY_PATH}/${VERSION}.tar.gz" -o "/tmp/versions/${VERSION}.tar.gz"
        
        if [ -f "/tmp/versions/${VERSION}.tar.gz" ]; then
            # Extract archive
            tar -xzf "/tmp/versions/${VERSION}.tar.gz" -C "/tmp/versions/$VERSION"
            
            # Create version directory in nginx and copy files
            mkdir -p "/usr/share/nginx/html/$VERSION"
            cp -r "/tmp/versions/$VERSION"/* "/usr/share/nginx/html/$VERSION/"
            
            echo "Version $VERSION successfully installed"
        else
            echo "Error downloading version $VERSION"
        fi
    fi
done

# Clean up temporary files
rm -rf /tmp/versions

echo "All versions successfully installed"
