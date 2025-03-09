# Versioned Nginx with Artifactory

This project demonstrates versioned static content delivery using Nginx and Artifactory.

## Project Structure
```
.
├── demo/                # Demo versions
│   ├── 1.0.0/
│   │   └── index.html
│   ├── 1.0.1/
│   │   └── index.html
│   └── 1.0.2/
│       └── index.html
├── artifactory/        # Artifactory configuration
│   ├── Dockerfile
│   └── artifactory.config.xml
├── docker-compose.yml   # Docker compose configuration
├── Dockerfile          # Nginx container configuration
├── package.json        # Version configuration
├── apply-versions.sh   # Script to fetch and apply versions
└── setup.sh           # Setup script
```

## Quick Start

1. **Setup the environment:**
```bash
# Make scripts executable
chmod +x setup.sh
./setup.sh
```

2. **Start the containers:**
```bash
# Start both Artifactory and Nginx
docker-compose up -d
```

3. **Configure Artifactory:**
- Wait for Artifactory to start (2-3 minutes)
- Open http://localhost:8081/artifactory
- Login with admin/password
- Create a new Generic repository named "versioned-assets"

4. **Package and upload versions:**
```bash
# Create archives from demo versions
cd demo/1.0.0 && tar -czf ../../1.0.0.tar.gz . && cd ../..
cd demo/1.0.1 && tar -czf ../../1.0.1.tar.gz . && cd ../..
cd demo/1.0.2 && tar -czf ../../1.0.2.tar.gz . && cd ../..

# Upload to Artifactory
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.0.tar.gz" -T 1.0.0.tar.gz
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.1.tar.gz" -T 1.0.1.tar.gz
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.2.tar.gz" -T 1.0.2.tar.gz
```

5. **Access the versions:**
- http://localhost/1.0.0
- http://localhost/1.0.1
- http://localhost/1.0.2

## Managing Versions

### Adding a New Version

1. Create a new version directory:
```bash
mkdir -p demo/1.0.3
```

2. Add your content:
```bash
echo "<html><body><h1>Version 1.0.3</h1></body></html>" > demo/1.0.3/index.html
```

3. Package and upload:
```bash
cd demo/1.0.3 && tar -czf ../../1.0.3.tar.gz . && cd ../..
curl -u admin:password -X PUT "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.3.tar.gz" -T 1.0.3.tar.gz
```

4. Update package.json with the new version:
```json
{
  "versionsConfig": {
    "versions": [
      {
        "version": "1.0.3",
        "releaseDate": "2024-03-10"
      },
      ...
    ]
  }
}
```

5. Restart the nginx container:
```bash
docker-compose restart nginx-versions
```

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Restart specific container
docker-compose restart nginx-versions
docker-compose restart artifactory

# Stop all containers
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Clean up everything
docker-compose down
rm -rf artifactory_tmp
```

## Troubleshooting

### Version not showing up
```bash
# Check nginx logs
docker-compose logs nginx-versions

# Verify file in Artifactory
curl -u admin:password -X GET "http://localhost:8081/artifactory/versioned-assets/web-assets/1.0.1.tar.gz"
```

### Artifactory issues
```bash
# Check Artifactory logs
docker-compose logs artifactory

# Verify Artifactory is running
docker-compose ps
```

### Network issues
```bash
# Check if containers are on the same network
docker network inspect app-network

# Verify Artifactory is accessible from nginx container
docker-compose exec nginx-versions curl -I http://artifactory:8081
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
