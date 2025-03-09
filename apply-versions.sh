#!/bin/bash

# Create temporary directory for versions
mkdir -p /tmp/versions

echo "Content of package.json:"
cat package.json

# Read and parse package.json using awk
ARTIFACTORY_PATH=$(awk -F'"' '/"artifactoryPath"/ {print $4}' package.json)
echo "ARTIFACTORY_PATH before environment check: $ARTIFACTORY_PATH"

# If ARTIFACTORY_URL is set, use it instead of localhost
if [ ! -z "$ARTIFACTORY_URL" ]; then
    echo "ARTIFACTORY_URL is set to: $ARTIFACTORY_URL"
    ARTIFACTORY_PATH="${ARTIFACTORY_URL#http://}/artifactory/versioned-assets/web-assets"
fi

echo "Final ARTIFACTORY_PATH: $ARTIFACTORY_PATH"

# Extract versions from versionsConfig section
echo "Extracting versions..."
VERSIONS=$(awk -F'[][]' '/versions/ {print $2}' package.json | tr -d '"' | tr ',' '\n' | tr -d ' ')

echo "Found versions:"
echo "$VERSIONS"

if [ -z "$VERSIONS" ]; then
    echo "No versions found in package.json!"
    exit 1
fi

for VERSION in $VERSIONS; do
    if [ ! -z "$VERSION" ]; then
        echo "Processing version: $VERSION"
        
        # Check if version exists in Artifactory
        DOWNLOAD_URL="http://${ARTIFACTORY_PATH}/${VERSION}.tar.gz"
        echo "Checking version $VERSION in Artifactory..."
        
        if curl -s -I -u admin:password "$DOWNLOAD_URL" | grep -q "HTTP/1.1 200"; then
            echo "Version $VERSION found in Artifactory"
            
            # Create directory for version
            mkdir -p "/tmp/versions/$VERSION"
            
            # Download archive
            echo "Downloading from: $DOWNLOAD_URL"
            curl -s -u admin:password "$DOWNLOAD_URL" -o "/tmp/versions/${VERSION}.tar.gz"
            
            if [ -f "/tmp/versions/${VERSION}.tar.gz" ]; then
                # Extract archive
                tar -xzf "/tmp/versions/${VERSION}.tar.gz" -C "/tmp/versions/$VERSION"
                
                # Create version directory in nginx and copy files
                mkdir -p "/usr/share/nginx/html/$VERSION"
                cp -r "/tmp/versions/$VERSION"/* "/usr/share/nginx/html/$VERSION/"
                
                echo "Version $VERSION successfully installed"
            else
                echo "Error downloading version $VERSION"
                echo "Curl exit code: $?"
            fi
        else
            echo "WARNING: Version $VERSION not found in Artifactory at $DOWNLOAD_URL"
            echo "Please ensure the version exists and is accessible"
        fi
    fi
done

# Clean up temporary files
rm -rf /tmp/versions

echo "All versions successfully installed"
